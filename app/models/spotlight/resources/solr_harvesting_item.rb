
include Spotlight::Resources::Exceptions
module Spotlight::Resources
  class SolrHarvestingItem
    attr_reader :titles, :id
    attr_accessor :metadata, :sidecar_data
    def initialize(exhibit, converter)
      @solr_hash = {}
      @exhibit = exhibit
      @converter = converter
    end
    
    def to_solr
      add_document_id
      solr_hash
    end
    
    def parse_record(unique_id_field)
      if (!metadata[unique_id_field].blank?)
        if (metadata[unique_id_field].kind_of?(Array))
          @id = metadata[unique_id_field][0]
        else
          @id = metadata[unique_id_field] 
        end
        
        #Strip out all of the decimals
        @id = @id.gsub('.', '')
        @id = @exhibit.id.to_s + "-" + @id.to_s
      end
      
      @solr_hash = @converter.convert(metadata)
      @sidecar_data = @converter.sidecar_hash
   end
  
   # private
    
    attr_reader :solr_hash, :exhibit

    
    def add_document_id
      if (!@id.blank?)
        solr_hash[:id] = @id.to_s
      else
        #Generate a random number if no unique id is supplied.
        solr_hash[:id] = rand.to_s[2..11] 
      end
    end
  
  end
end