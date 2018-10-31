# Spotlight::Resources::Oaipmh

Spotlight Resource Harvester for OAI-PMH.  A Rails engine gem for use in the blacklight-spotlight Rails engine gem.

## Installation

Add this line to your blacklight-spotlight Rails application's Gemfile:

```ruby
gem 'spotlight-oaipmh-resources'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install spotlight-oaipmh-resources

Then run the engine's generator:

    $ rails generate spotlight:oaipmh:resources:install

Furthermore, this engine runs the harvester as a background job.  To set up the job, install delayed_job
in your Spotlight Gemfile:
```ruby 
gem 'delayed_job_active_record'
gem 'daemons'
```

Add the delayed_job initializer to config/initializers/delayed_job.rb.  Here is a sample delayed_job.rb file:
```ruby 
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))

if Rails.env.production? || Rails.env.development?
  # Check if the delayed job process is already running
  # Since the process loads the rails env, this file will be called over and over
  # Unless this condition is set.
  pids = Dir.glob(Rails.root.join('tmp','pids','*'))

  system "echo \"delayed_jobs INIT check\""
  if pids.select{|pid| pid.start_with?(Rails.root.join('tmp','pids','delayed_job.init').to_s)}.empty?

    f = File.open(Rails.root.join('tmp','pids','delayed_job.init'), "w+") 
    f.write(".")
    f.close
    system "echo \"Restatring delayed_jobs...\""
    system "RAILS_ENV=#{Rails.env} #{Rails.root.join('bin','delayed_job')} stop"
    system "RAILS_ENV=#{Rails.env} #{Rails.root.join('bin','delayed_job')} start"
    system "echo \"delayed_jobs Workers Initiated\""
    File.delete(Rails.root.join('tmp','pids','delayed_job.init')) if File.exist?(Rails.root.join('tmp','pids','delayed_job.init'))

  else
    system "echo \"delayed_jobs is running\""
  end
end
```

Make a tmp/pids directory:

	$ mkdir tmp/pids

Generate the binstub and delayed_record migration

	$ bundle exec rails generate delayed_job:active_record

Add the delayed_job as the queue_adapter to config/application.rb:

```ruby
config.active_job.queue_adapter = :delayed_job
```

## Usage

This is a Rails engine gem to be used along with blacklight-spotlight, another Rails engine gem used to build exhibits sites while leveraging the blacklight Rails engine gem.

This gem adds a new "Repository Item" form to your Spotlight application. This form allows curators to input a URL pointing to an OIA harvest and a set, and the contents of the feed will be harvested as new items in the Spotlight exhibit.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/harvard-library/spotlight-oaipmh-resources.



