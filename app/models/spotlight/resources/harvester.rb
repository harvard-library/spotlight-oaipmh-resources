module Spotlight::Resources
  class Harvester < Spotlight::Resource
    attr_accessor :set, :base_url, :mapping_file, :solr_mapping_file, :user
            
    def harvests
      harvester = get_harvester
      harvester.get_harvests
      
    end
    
    #Override the document builder since the builder has to be determined after insantiation
    def document_builder
      if (self.data[:type] == Spotlight::Resources::HarvestType::SOLR)
        @document_builder = Spotlight::Resources::SolrHarvestingBuilder.new(self)
      else
        @document_builder = Spotlight::Resources::OaipmhBuilder.new(self)
      end
    end
    
    #The harvester will know what type of token to expect
    def paginate (token)
      harvester = get_harvester
      harvester.paginate(token)
    end
    
    def get_job_entry
      self.data[:job_entry]
    end
    
    private
    
    def get_harvester
      if @harvester.nil?
        if (self.data[:type] == Spotlight::Resources::HarvestType::SOLR)
          self.document_builder_class = Spotlight::Resources::SolrHarvestingBuilder
          @harvester = SolrHarvester.new(self.data[:base_url], self.data[:set])
        else
          self.document_builder_class = Spotlight::Resources::OaipmhBuilder
          @harvester = OaipmhHarvester.new(self.data[:base_url], self.data[:set])
        end
      end
      @harvester
    end
  end
  
end
