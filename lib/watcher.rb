module ProfileProbe

  class Watcher

    def initialize(config)

      @process_regex_list = config['process_regex_list'].map do |regex_str|
        Regexp.new(regex_str)
      end

      # Empty process list
      @known_process_list = ::ProcFS::ProcessList.new
    end

    def probe

      socket_list = ::ProcFS::SocketList.scan

      process_list  = ::ProcFS::ProcessList.scan(socket_list)
      process_list  = process_list.filter_by_regex(:cmdline, @process_regex_list) unless @process_regex_list.empty?

      unless @known_process_list == process_list

        delta_struct = {
          :timestamp => Time.now.utc,
          :new_state => process_list.state_hash,
          :old_state => @known_process_list.state_hash
        }

        new_process_list = process_list.diff_ids(@known_process_list)
        old_process_list = @known_process_list.diff_ids(process_list)
        fresh_process_list_raw = process_list.diff_states @known_process_list
        stale_process_list_raw = @known_process_list.diff_states process_list
        fresh_process_list = fresh_process_list_raw.diff_ids(new_process_list)
        stale_process_list = stale_process_list_raw.diff_ids(old_process_list)
        delta_process_list = fresh_process_list - stale_process_list

        delta_struct[:spawned] = new_process_list unless new_process_list.empty?
        delta_struct[:killed] = old_process_list unless old_process_list.empty?
        delta_struct[:delta] = delta_process_list unless delta_process_list.empty?

        deltas = ::ProcFS::PropertyBag.new(delta_struct)
        deltas.separator ="\n\n"

        puts deltas
        puts
        puts
      end

      @known_process_list = process_list

    end

  end

end