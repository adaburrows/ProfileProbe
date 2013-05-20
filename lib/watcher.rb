module ProfileProbe

  class Watcher

    def initialize(config)

      @process_regex_list = config['process_regex_list'].map do |regex_str|
        Regexp.new(regex_str)
      end

      # Empty process list
      @known_process_info = ::ProcFS::ProcessList.new({})

    end

    def probe

      process_info  = ::ProcFS::ProcessList.new(nil, ::ProcFS::SocketList.new)
      process_info  = process_info.filter_by_regex(@process_regex_list) unless @process_regex_list.empty?

      unless @known_process_info == process_info
        puts "\n\n="
        puts Time.now.utc.to_s
        puts "It changed: #{@known_process_info.state_hash} vs #{process_info.state_hash}\n="
        fresh_process_info = process_info - @known_process_info
        stale_process_info = @known_process_info - process_info
        puts "\n********** FRESH STATE **********\n#{fresh_process_info}" unless fresh_process_info.empty?
        puts "\n********** STALE STATE **********\n#{stale_process_info}\n" unless stale_process_info.empty?
      end

      @known_process_info = process_info

    end

  end

end