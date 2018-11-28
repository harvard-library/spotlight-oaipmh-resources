require 'oai'
require 'net/http'
require 'uri'
  
module Spotlight::Resources
  class OaipmhHarvester
    
    def initialize(base_url, set)
     @url = base_url + '?verb=ListRecords&metadataPrefix=mods&set=' + set
      @base_url = base_url
      @set = set
    end
            
    def get_harvests
      @client = OAI::Client.new @base_url
      @oaipmh_harvests = @client.list_records :set => @set, :metadata_prefix => 'mods'
    end
    
    def paginate (token)
      if @client.nil?
        @client = OAI::Client.new @base_url
      end
      @oaipmh_harvests = @client.list_records :resumption_token => token
    end
    
    def self.mapping_files
      if (Dir.exist?('public/uploads/modsmapping'))
        files = Dir.entries('public/uploads/modsmapping')
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
