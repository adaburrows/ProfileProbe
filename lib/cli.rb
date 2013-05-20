require ::File.expand_path("./proc_fs/index", File.dirname(__FILE__))
require 'json'

module ProfileProbe

  class CLI

    def initialize
      if ENV['CONF'].nil?
        @config = {}
      else
        @config = JSON.parse(IO.read(ENV['CONF']))
      end
      @config['process_regex_list'] = [] if @config['process_regex_list'].nil?

      @watcher = ::ProfileProbe::Watcher.new(@config)
    end

    def stop_it
      puts "Terminating..."
      @running = false
    end

    def run
      @running = true

      loop do
        break if !@running

        @watcher.probe

        sleep 0.001
      end

    end

  end

end