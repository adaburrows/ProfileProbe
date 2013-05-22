module ProfileProbe

  class Watcher

    def initialize(config)

      @process_regex_list = config['process_regex_list'].map do |regex_str|
        Regexp.new(regex_str)
      end

      # Empty process list
      @known_process_list = ::ProcFS::ProcessList.new
      @known_socket_list = ::ProcFS::SocketList.new
    end

    def probe

      socket_list = ::ProcFS::SocketList.scan

      process_list  = ::ProcFS::ProcessList.scan(socket_list)
      process_list  = process_list.filter_by_regex(:cmdline, @process_regex_list) unless @process_regex_list.empty?

      unless @known_process_list == process_list
        puts "\n\n#{Time.now.utc.to_s}"

        new_process_list = process_list.diff_ids(@known_process_list)
        old_process_list = @known_process_list.diff_ids(process_list)
        fresh_process_list_raw = process_list.diff_states @known_process_list
        stale_process_list_raw = @known_process_list.diff_states process_list
        fresh_process_list = fresh_process_list_raw.diff_ids(new_process_list)
        stale_process_list = stale_process_list_raw.diff_ids(old_process_list)
        delta_process_list = fresh_process_list - stale_process_list

        puts "SPAWNED\n#{new_process_list}" unless new_process_list.empty?
        puts "KILLED\n#{old_process_list}" unless old_process_list.empty?
        puts "DELTA\n#{delta_process_list}" unless delta_process_list.empty?
      end

      @known_process_list = process_list

    end

  end

end