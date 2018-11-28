module Spotlight
  ##
  # Notify the curator that we're finished processing a
  # batch upload
  class HarvestingCompleteMailer < ActionMailer::Base
    def harvest_indexed(set, exhibit, user, failed_items)
      @set = set
      @exhibit = exhibit
      @failed_items = failed_items
      mail(to: user.email, from: 'oaiharvester@noreply.com', subject: 'Harvest indexing complete for '+ set)
    end
    
    def harvest_failed(set, exhibit, user, message)
      @set = set
      @exhibit = exhibit
      @message = message
      mail(to: user.email, from: 'oaiharvester@noreply.com', subject: 'The harvest failed for '+ set)
    end
  end
end
