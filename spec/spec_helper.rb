# frozen_string_literal: true

require 'bundler/setup'
require 'hover/pub_sub'

# Stolen from https://github.com/ursm/activejob-google_cloud_pubsub/blob/master/spec/spec_helper.rb
def run_pubsub_emulator(&block)
  project_id = 'hover-pubsub-ruby-specs'
  pipe = IO.popen("gcloud beta emulators pubsub start --project=#{project_id}", err: %i[child out], pgroup: true)

  begin
    Timeout.timeout 10 do
      pipe.each do |line|
        break if line.include?('INFO: Server started')
        raise line if line.include?('Exception in thread')
      end
    end

    port = `gcloud beta emulators pubsub env-init`.match(/^export PUBSUB_EMULATOR_HOST=.*:(\S+)$/).captures.first
    host = "localhost:#{port}"

    block.call host, project_id
  ensure
    begin
      Process.kill :TERM, -Process.getpgid(pipe.pid)
      Process.wait pipe.pid
    rescue Errno::ESRCH, Errno::ECHILD
      # already terminated
    end
  end
end

def create_topic(name); end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around :each, use_pubsub_emulator: true do |example|
    run_pubsub_emulator do |host, project_id|
      ENV['PUBSUB_EMULATOR_HOST'] = host
      @pubsub_project_id = project_id

      example.run

      ENV.delete('PUBSUB_EMULATOR_HOST')
    end
  end
end
