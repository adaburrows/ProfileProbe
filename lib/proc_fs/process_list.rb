module ProcFS

  class ProcessList

    attr_accessor :processes, :state_hash

    def initialize(processes = nil, socket_descriptors = nil)
      if processes.nil?
        @processes = scan_procs(socket_descriptors)
      else
        @processes = processes
      end
      @state_hash = generate_state_hash
    end

    def scan_procs(socket_descriptors = nil)
      processes = {}

      Dir.entries("/proc/").each do |pid|
        if File.directory?("/proc/#{pid}/") and /[\d]+/ =~ pid and pid.to_s != ::Process.pid.to_s
          begin
            proc = ::ProcFS::ProcessDescriptor.new(pid, socket_descriptors)
            processes[proc.state_hash] = proc
          rescue
            puts "Process #{pid} must have died."
          end
        end
      end

      processes
    end

    def get_pid_for(process_regex)
      pid_match = nil
      @processes.each do |pid, process|
        pid_match = pid if process_regex =~ process.cmdline
      end
      pid_match
    end

    def filter_by_regex(process_regex_list)
      process_matches = {}
      @processes.each do |pid, process|
        process_regex_list.each do |process_regex|
          process_matches[pid] = process if process_regex =~ process.cmdline
        end
      end
      ProcessList.new(process_matches)
    end

    def -(rhs_process_list)
      rhs_state_hashes = rhs_process_list.processes.keys
      lhs_state_hashes = @processes.keys
      lhs_only_state_hashes = lhs_state_hashes - rhs_state_hashes

      lhs_only_processes = @processes.select { |h,s| lhs_only_state_hashes.member? h }

      ProcessList.new(lhs_only_processes)
    end

    def empty?
      @processes.empty?
    end

    def generate_state_hash
      Digest::SHA1.hexdigest(@processes.keys.join)
    end

    def to_s
      process_strings = []
      @processes.each { |pid, process| process_strings << process.to_s }
      process_strings.join("\n\n")

    end

    def ==(rhs_process_list)
      state_hash == rhs_process_list.state_hash
    end

  end

end