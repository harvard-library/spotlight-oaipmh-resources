include Spotlight::Resources::Exceptions
module Spotlight::Resources
  
  class SolrEntry
     attr_accessor :solr_field
   end
  class ConverterItem
    attr_accessor :spotlight_field, :solr_items, :default_value, :delimiter, :multivalue_facets
        
    def initialize()
      delimiter = ", "
    end
    
    def extract_values(solrmd)
      
      values = extract_solr_values(solrmd)
      
      #Remove duplicates
      values = values.uniq
      
      finalvalue = nil
      if (!values.empty?)
        #if multiple values, allow for faceting on each item by keeping it as an array
        if (!multivalue_facets.nil? && (multivalue_facets.eql?("yes") || multivalue_facets))
          
          finalvalue = values;
        else
          finalvalue = values.join(delimiter)
        end
      end 
      finalvalue
    end
    
private
    
    def extract_solr_values(solrmd)
      values = Array.new
      if (!solr_items.nil?)
        retvals = Array.new
        solr_items.each do |item|
          myretval = solrmd[item.solr_field]
          
          if (myretval.blank? && !default_value.blank?)
            value = default_value
            values << value
          elsif (!myretval.blank?)
            values << myretval
          end
        end
      end
      values
    end

end
  
  class SolrConverter
    STANDARD_SPOTLIGHT_FIELDS = ['unique-id_tesim', 'full_title_tesim', 'spotlight_upload_description_tesim', 'thumbnail_url_ssm', 'full_image_url_ssm', 'spotlight_upload_date_tesim"', 'spotlight_upload_attribution_tesim']
      
    attr_accessor :sidecar_hash
       
    #Initialize with the name of the set being converted
    def initialize(set, exhibitslug, mapping_file)
      @set = set
      @exhibitslug = exhibitslug
      @mapping_file = mapping_file   
      @converter_items = Array.new  
      @sidecar_hash = {}
    end
    
    def convert(solrrecord)
      if (@converter_items.empty?)
        parse_mapping_file(mapping_file)
      end
      
      solr_hash = {}
        
      @converter_items.each do |item|
        value = item.extract_values(solrrecord)
          
      #Not sure why but if a value isn't assigned, the last existing value for the field gets
      #placed in all non-existing values
       solr_hash[get_spotlight_field_name(item.spotlight_field)] = value
       @sidecar_hash[item.spotlight_field] = value

      end
      solr_hash
    end
    
    #Some spotlight fields use the exhibit slug, others do not
    def get_spotlight_field_name(spotlight_field)      
      if (!STANDARD_SPOTLIGHT_FIELDS.include?(spotlight_field))
        spotlight_field = 'exhibit_' + @exhibitslug + '_' + spotlight_field
      end
      spotlight_field
    end
    

    #Retrieves the mapping file for the set, if one exists, otherwise uses the generic mapping file
    def mapping_file
      if (@mapping_file == nil)
        engine_root = Spotlight::Oaipmh::Resources::Engine.root
        @mapping_file = File.join(engine_root, 'config', 'default_solr_mapping.yml')
      else
        @mapping_file = Rails.root.join("public/uploads/solrmapping", @mapping_file)
      end
      @mapping_file        
    end

  
  #private
  
   #parses the mapping file into a model
  def parse_mapping_file(file)
    
    mapping_config = YAML.load_file(file)
    mapping_config.each do |field|
      
      item = ConverterItem.new
      #validate the spotlight-field is not null
      if (!field.key?("spotlight-field") || field['spotlight-field'].blank?)
        raise InvalidMappingFile, "spotlight-field is required for each entry"
      end
      item.spotlight_field = field['spotlight-field']
      
      if (field.key?("delimiter"))
        item.delimiter = field["delimiter"]
      end
      if (field.key?("default-value"))
        item.default_value = field["default-value"]
      end

      if (field.key?("multivalue-breaks"))
        item.multivalue_facets = field["multivalue-breaks"]
      end
      
      #must have a solr-field value 
      if (!field.key?("solr-field"))
        raise InvalidMappingFile, "solr-field is required for each entry"
      end
      
      #if using xpath, then add the values from xpath
      if (field.key?('solr-field'))
        item.solr_items = Array.new
        field['solr-field'].each do |solr_field|
          if (!solr_field.key?("field-name") || solr_field['field-name'].blank?)
            raise InvalidMappingFile, "field-name is required for each solr-field entry"
          end
          
          solritem = SolrEntry.new
          solritem.solr_field = solr_field['field-name']
          item.solr_items << solritem

        end
      end
      
      #If it is the unique field, set it
      if (field['spotlight-field'].eql?("unique-id_tesim"))
        delimiter = ""
        if (!field["delimiter"].blank?)
          delimiter = field["delimiter"]
        end
        
        fields = Array.new
        item.solr_items.each do |solr_item|
          fields << solr_item.solr_field
        end
        @unique_id_field = fields.join(delimiter)
      end
      
      @converter_items << item
    end
    @converter_items
  end
  
  def get_unique_id_field()
    @unique_id_field
  end
  
  end
end