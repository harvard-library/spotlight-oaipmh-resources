module Spotlight
  module Resources
    # transforms a OaipmhHarvester into solr documents
    class OaipmhBuilder < Spotlight::SolrDocumentBuilder
      
      def to_solr
        begin
        return to_enum(:to_solr) { 0 } unless block_given?

        base_doc = super
          
           
        mapping_file = nil
        if (!resource.data[:mapping_file].eql?("Default Mapping File") && !resource.data[:mapping_file].eql?("New Mapping File"))
          mapping_file = resource.data[:mapping_file]
        end
 
        max_batch_count = Spotlight::Oaipmh::Resources::Engine.config.oai_harvest_batch_max
                   
        @oai_mods_converter = OaipmhModsConverter.new(resource.data[:set], resource.exhibit.slug, mapping_file)
        
        count = 0
        totalrecords = 0
        failed_items = nil

    		#If the resumption token was stored, begin there.
        if (resource.data.include?(:cursor) && !resource.data[:cursor].blank?)
          cursor = resource.data[:cursor]
          harvests = resource.paginate(cursor)
          
   			else
          harvests = resource.harvests
        end
     		
     		resumption_token = harvests.resumption_token
     		
     		if (resource.data.include?(:count) && !resource.data[:count].blank?)
          totalrecords = resource.data[:count]
        end
        
        last_page_evaluated = false
        while (!last_page_evaluated)
          if (resumption_token.nil?)
            last_page_evaluated = true
          end

          harvests.each do |record|
            @item = OaipmhModsItem.new(exhibit, @oai_mods_converter)
            @item.metadata = record.metadata
            #Temporary fix for resumption token issue on LC end
            #Check to see if the count is 0 or 1 and if the first identifier is blank
            if (resource.data[:count].blank? || resource.data[:count] == 1)
              if (@item.has_blank_identifier?)
                last_page_evaluated = true
                resumption_token = nil
                break
              end
            end
            @item.parse_mods_record()
            begin
              @item_solr = @item.to_solr
              @item_sidecar = @item.sidecar_data
              
              repository_field_name = @oai_mods_converter.get_spotlight_field_name("repository_ssim")
              
              process_images()

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
              if (failed_items.nil?)
                failed_items = Array.new
              end
              failed_items << @item.id
            end
          end

          #Stop harvesting if the batch has reached the maximum allowed value
          if (!resumption_token.nil?) 
        		if (max_batch_count != -1 && count >= max_batch_count)
              schedule_next_batch(resumption_token, totalrecords, failed_items)
        		  break
        		else
             harvests = resource.paginate(resumption_token)
             resumption_token = harvests.resumption_token
            end
          end
        
        end
        rescue Exception => e
          resource.get_job_entry.failed!
          Delayed::Worker.logger.add(Logger::ERROR, resource.data[:set] + ' harvest failed')
          Delayed::Worker.logger.add(Logger::ERROR, e.message)
          Delayed::Worker.logger.add(Logger::ERROR, e.backtrace)
          Spotlight::HarvestingCompleteMailer.harvest_failed(resource.data[:set], resource.exhibit, resource.data[:user], e.message).deliver_now
          raise
        end
        if (last_page_evaluated)
        	resource.get_job_entry.succeeded!
        	#Send job message
          Spotlight::HarvestingCompleteMailer.harvest_indexed(resource.data[:set], resource.exhibit, resource.data[:user], failed_items).deliver_now
       	end
      end

private   
      def schedule_next_batch(cursor, count, failed_items)
        Spotlight::Resources::PerformHarvestsJob.perform_later(resource.data[:type], resource.data[:base_url], resource.data[:set], resource.data[:mapping_file], resource.exhibit, resource.data[:user], resource.data[:job_entry], cursor, count, failed_items)
      end
            
      def process_images()
        if (@item_solr.key?('thumbnail_url_ssm') && !@item_solr['thumbnail_url_ssm'].blank? && !@item_solr['thumbnail_url_ssm'].eql?('null'))           
          thumburl = fetch_ids_uri(@item_solr['thumbnail_url_ssm'])
          if (!thumburl.blank? && !thumburl.eql?('null'))
            thumburl = transform_ids_uri_to_iiif(thumburl)
            @item_solr['thumbnail_url_ssm'] =  thumburl
          end    
        end
        if (@item_solr.key?('full_image_url_ssm') && !@item_solr['full_image_url_ssm'].blank? && !@item_solr['full_image_url_ssm'].eql?('null'))           
          
          fullurl = fetch_ids_uri(@item_solr['full_image_url_ssm'])
          if (!fullurl.blank?)

            #If it is http, make it https            
            if (fullurl.include?('http://'))
              fullurl = fullurl.sub(/http:\/\//, "https://")
            end
            #if it is IDS, then add ?buttons=y so that mirador works
            if (fullurl.include?('https://ids') && !fullurl.include?('?buttons=y'))
              fullurl = fullurl + '?buttons=y'
            end
            @item_solr['full_image_url_ssm'] =  fullurl
          end
        end
      end

      
      #Resolves urn-3 uris
      def fetch_ids_uri(uri_str)
        if (uri_str =~ /urn-3/)
          response = Net::HTTP.get_response(URI.parse(URI.encode(uri_str)))['location']
        elsif (uri_str.include?('?'))
          uri_str = uri_str.slice(0..(uri_str.index('?')-1))
        else
          uri_str
        end
      end
    
      #Returns the uri for the iiif
      def transform_ids_uri_to_iiif(ids_uri)
        #Strip of parameters
        uri = ids_uri.sub(/\?.+/, "")
        #Change /view/ to /iiif/
        uri = uri.sub(%r|/view/|, "/iiif/")
        #Append /native.jpg to end if it doesn't exist
        if (!uri.include?('native.jpg'))
          uri = uri + "/full/180,/0/native.jpg"
        elsif (uri.include?("full/,150/"))
          uri = uri.sub(/full\/,150\//,"full/180,/")
        end    
        uri
      end

    end
  end
end
