require 'spotlight/engine'

module Spotlight::Oaipmh::Resources
  class Engine < ::Rails::Engine
   
    Spotlight::Oaipmh::Resources::Engine.config.resource_partial = 'spotlight/resources/harvester/form'
    #The maximum number of records to harvest in one batch using OAI
    #Use -1 to set no boundary
    config.oai_harvest_batch_max = 10000
    #The maximum number of records to harvest in one batch using Solr
    #Use -1 to set no boundary
    config.solr_harvest_batch_max = 10000
        
    initializer 'spotlight.oaipmh.initialize' do
      Spotlight::Engine.config.external_resources_partials ||= []
      Spotlight::Engine.config.external_resources_partials << Spotlight::Oaipmh::Resources::Engine.config.resource_partial
    end
    config.generators do |g|
      g.test_framework :rspec
    end
    
  end
end
