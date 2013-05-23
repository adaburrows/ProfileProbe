require ::File.expand_path("./proc_fs/index", File.dirname(__FILE__))

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
      @running = false
    end

    def run
      @running = true

      loop do
        break if !@running

        results = @watcher.probe
        puts JSON.pretty_generate(results.to_hash) + "\r\n\r\n" unless results.nil?

        sleep 0.005
      end

    end

  end

end