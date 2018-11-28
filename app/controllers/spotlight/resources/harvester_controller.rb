
module Spotlight::Resources
  class HarvesterController < Spotlight::ApplicationController
    
    load_and_authorize_resource :exhibit, class: Spotlight::Exhibit
    
    # POST /oaipmh_harvester
    def create
      
      my_params = resource_params
      
      #upload the mapping file if it exists
      if (my_params.has_key?(:custom_mapping))
        upload
        my_params.delete(:custom_mapping)
      end
      mapping_file = resource_params[:mapping_file]
      if (resource_params[:type]  == Spotlight::Resources::HarvestType::SOLR)
        mapping_file = resource_params[:solr_mapping_file]
      end
      if (resource_params.has_key?(:custom_mapping))
        mapping_file = resource_params[:custom_mapping].original_filename
      end
      
      Spotlight::Resources::PerformHarvestsJob.perform_later(resource_params[:type], resource_params[:url], resource_params[:set], mapping_file, current_exhibit, current_user, new_job_log_entry)
      flash[:notice] = t('spotlight.resources.harvester.performharvest.success', set: resource_params[:set])
      redirect_to spotlight.admin_exhibit_catalog_path(current_exhibit, sort: :timestamp)
    end
    
  private
    
    def upload
      name = resource_params[:custom_mapping].original_filename
      Dir.mkdir("public/uploads") unless Dir.exist?("public/uploads")  
      dir = "public/uploads/modsmapping"
      if (resource_params[:type]  == Spotlight::Resources::HarvestType::SOLR)
        dir = "public/uploads/solrmapping"
      end
      Dir.mkdir(dir) unless Dir.exist?(dir)
      
      path = File.join(dir, name)
      File.open(path, "w") { |f| f.write(resource_params[:custom_mapping].read) }
    end


    def resource_params
      params.require(:resources_harvester).permit(:type, :url, :set, :mapping_file, :solr_mapping_file, :custom_mapping)
    end
    
    #Set the job status so users can view
    def new_job_log_entry
      Spotlight::JobLogEntry.create(exhibit: current_exhibit, user: current_user, job_item_count: 0, job_status: 'unstarted', job_type: 'Harvesting')
    end
       
    
  end

end
