module ProcFS

  class ProcessList

    attr_accessor :id_index, :state_index, :state_hash

    def self.scan(socket_descriptors = nil)
      scan_id_index = {}
      scan_state_index = {}

      Dir.entries("/proc/").each do |pid|
        if File.directory?("/proc/#{pid}/") and /[\d]+/ =~ pid and pid.to_s != ::Process.pid.to_s
          begin
            process_descriptor = ::ProcFS::ProcessDescriptor.new(pid, socket_descriptors)
            scan_id_index[pid] = process_descriptor
            scan_state_index[process_descriptor.state_hash] = process_descriptor
          rescue
            puts "Process #{pid} died while attempting to read its /proc/ entry."
          end
        end
      end

      return ProcessList.new(scan_id_index, scan_state_index)
    end

    def initialize(passthrough_id_index = {}, passthrough_state_index = {})
      @id_index = passthrough_id_index
      @state_index = passthrough_state_index
      @state_hash = generate_state_hash
    end

    def get_pid_for(process_regex)
      id_match = nil
      @id_index.each do |pid, process_descriptor|
        id_match = pid if process_regex =~ process_descriptor.cmdline
      end

      return id_match
    end

    def filter_by_regex(process_regex_list)
      filtered_id_index = {}
      filtered_state_index = {}

      @id_index.each do |pid, process_descriptor|
        process_regex_list.each do |process_regex|
          if process_regex =~ process_descriptor.cmdline
            filtered_id_index[pid] = process_descriptor
            filtered_state_index[process_descriptor.state_hash] = process_descriptor
          end
        end
      end

      return ProcessList.new(filtered_id_index, filtered_state_index)
    end

    ## TODO: Function diffs state across two lists sharing the same pids
    def diff_states_by_pid(rhs_process_list)

      @id_index.each do |pid, process_descriptor|
      end

    end

    def diff_ids(rhs_process_list)
      delta_id_index = {}
      delta_state_index = {}

      rhs_ids = rhs_process_list.id_index.keys
      lhs_ids = @id_index.keys

      delta_ids = lhs_ids - rhs_ids

      delta_ids.each do |pid|
        process_descriptor = @id_index[pid]
        delta_id_index[pid] = process_descriptor
        delta_state_index[process_descriptor.state_hash] = process_descriptor
      end

      return ProcessList.new(delta_id_index, delta_state_index)
    end

    def diff_states(rhs_process_list)
      delta_id_index = {}
      delta_state_index = {}

      rhs_state_hashes = rhs_process_list.state_index.keys
      lhs_state_hashes = @state_index.keys

      delta_state_hashes = lhs_state_hashes - rhs_state_hashes

      delta_state_hashes.each do |hash|
        process_descriptor = @state_index[hash]
        delta_id_index[process_descriptor.pid] = process_descriptor
        delta_state_index[hash] = process_descriptor
      end

      return ProcessList.new(delta_id_index, delta_state_index)
    end

    def empty?
      @id_index.empty?
    end

    def each_by_id
      @id_index.each do |id, process_descriptor|
        yield id, process_descriptor
      end
    end

    def each_by_state
      @state_index.each do |hash, process_descriptor|
        yield hash, process_descriptor
      end
    end

    def generate_id_hash
      ::Digest::MD5.hexdigest(@id_index.keys.join)
    end

    def generate_state_hash
      ::Digest::MD5.hexdigest(@state_index.keys.join)
    end

    def to_s
      process_strings = []
      @id_index.each { |pid, process_descriptor| process_strings << process_descriptor.to_s }
      process_strings.join("\n\n")

    end

    def ==(rhs_process_list)
      generate_state_hash == rhs_process_list.generate_state_hash
    end

  end

end