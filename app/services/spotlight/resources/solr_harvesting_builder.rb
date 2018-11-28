module Spotlight
  module Resources
    # transforms a OaipmhHarvester into solr documents
    class SolrHarvestingBuilder < Spotlight::SolrDocumentBuilder
      
      def to_solr
        begin
        return to_enum(:to_solr) { 0 } unless block_given?

        base_doc = super
           
        mapping_file = nil
        if (!resource.data[:solr_mapping_file].eql?("Default Mapping File") && !resource.data[:solr_mapping_file].eql?("New Mapping File"))
          mapping_file = resource.data[:mapping_file]
        end

        max_batch_count = Spotlight::Oaipmh::Resources::Engine.config.solr_harvest_batch_max
        
        @solr_converter = SolrConverter.new(resource.data[:set], resource.exhibit.slug, mapping_file)
        @solr_converter.parse_mapping_file(@solr_converter.mapping_file) 

        unique_id_field = nil 
        if (!@solr_converter.get_unique_id_field.nil?)
          unique_id_field = @solr_converter.get_unique_id_field
        end
                 
        count = 0
        totalrecords = 0
        
        #If the resumption token was stored, begin there.
        if (resource.data.include?(:cursor) && !resource.data[:cursor].blank?)
          page = resource.data[:cursor]
          harvests = resource.paginate(page)
        else
          page = 1
          harvests = resource.harvests
        end

        if (resource.data.include?(:count) && !resource.data[:count].blank?)
          totalrecords = resource.data[:count]
        end

        last_page_evaluated = harvests['response']['docs'].blank?

        while (!last_page_evaluated)
          harvests['response']['docs'].each do |record|
            @item = SolrHarvestingItem.new(exhibit, @solr_converter)
            
            @item.metadata = record
            @item.parse_record(unique_id_field)
            begin
              @item_solr = @item.to_solr
              @item_sidecar = @item.sidecar_data
              
              #Add the sidecar info for editing
              sidecar ||= resource.document_model.new(id: @item.id).sidecar(resource.exhibit) 
              sidecar.update(data: @item_sidecar)
              yield base_doc.merge(@item_solr) if @item_solr.present?

              count = count + 1
              totalrecords = totalrecords + 1
              curtime = Time.zone.now
              resource.get_job_entry.update(job_item_count: totalrecords, end_time: curtime)

            rescue Exception => e
              Delayed::Worker.logger.add(Logger::ERROR, @item.id + ' did not index successfully')
              Delayed::Worker.logger.add(Logger::ERROR, e.message)
              Delayed::Worker.logger.add(Logger::ERROR, e.backtrace)
            end
          end #End of each loop
          page = page + 1
          #Stop harvesting if the batch has reached the maximum allowed value
          if (!last_page_evaluated) 
            if (max_batch_count != -1 && count >= max_batch_count)
              schedule_next_batch(page, totalrecords)
              break
            else
             harvests = resource.paginate(page)
             
            end
          end
          
                    
          #Terminate the loop if it is empty        
          if (harvests['response']['docs'].blank?)
            last_page_evaluated = true
          end
        end #End of while loop
        rescue
          resource.get_job_entry.failed!
          raise
        end
        if (last_page_evaluated)
          resource.get_job_entry.succeeded!
        end

      end
      
      def get_unique_id_field_name(mapping_file)
        mapping_config = YAML.load_file(mapping_file)
        mapping_config.each do |field|
          if (!field.key?("spotlight-field") || field['spotlight-field'].blank?)
            raise InvalidMappingFile, "spotlight-field is required for each entry"
          end
        end
      end
      
      def schedule_next_batch(cursor, count)
        Spotlight::Resources::PerformHarvestsJob.perform_later(resource.data[:type], resource.data[:base_url], resource.data[:set], resource.data[:mapping_file], resource.exhibit, resource.data[:user], resource.data[:job_entry], cursor, count)
      end


    end
  end
end
