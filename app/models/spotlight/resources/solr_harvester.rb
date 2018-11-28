require 'net/http'
require 'uri'
  
module Spotlight::Resources
  class SolrHarvester
    ROW_COUNT = 50
        
    def initialize(base_url, set)
      @url = base_url + set
      @base_url = base_url
      @set = set
    end
            
    def get_harvests
      @solr_connection = RSolr.connect :url => @url  
      response = @solr_connection.paginate 0, ROW_COUNT, 'select', :params => {:q => '*:*', :wt => 'json'}
    end
    
    def paginate (page)
      if (@solr_connection.nil?)
        @solr_connection = RSolr.connect :url => @url  
      end
      response = @solr_connection.paginate page, ROW_COUNT, 'select', :params => {:q => '*:*', :wt => 'json'}
    end
    
    
    def self.mapping_files
      if (Dir.exist?('public/uploads/solrmapping'))
        files = Dir.entries('public/uploads/solrmapping')
        files.delete(".")
        files.delete("..")
      else
        files = Array.new
      end
      
      files.insert(0, "New Mapping File")
      files.insert(0, "Default Mapping File")
      files
    end

  end
end
