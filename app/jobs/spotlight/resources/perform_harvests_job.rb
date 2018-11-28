require 'oai'
require 'net/http'
require 'uri'
require_relative '../../../mailer/spotlight/harvesting_complete_mailer'
include Spotlight::Resources::Exceptions
 # encoding: utf-8
module Spotlight::Resources
  ##
  # Process a CSV upload into new Spotlight::Resource::Upload objects
  class PerformHarvestsJob < ActiveJob::Base
    queue_as :default    

    before_perform do |job|
      job_log_entry = log_entry(job)
      job_log_entry.in_progress! if job_log_entry
    end

    def perform(harvest_type, url, set, mapping_file, exhibit, _user, job_entry, cursor = nil, count = 0, failed_items = nil)
      harvester = Spotlight::Resources::Harvester.create(
          url: url,
          data: {base_url: url,
                set: set,
                mapping_file: mapping_file,
                job_entry: job_entry,
                type: harvest_type,
                user: _user,
                cursor: cursor,
                count: count,
                failed_items: failed_items},
          exhibit: exhibit)
      if !harvester.save_and_index
        raise HarvestingFailedException
      end 
    end
 
 private
    
    def log_entry(job)
        job.arguments[6] if job.arguments[6].is_a?(Spotlight::JobLogEntry)
    end
  
  end

end
