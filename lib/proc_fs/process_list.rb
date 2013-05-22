module ProcFS

  class ProcessList < ::ProcFS::IdStateList

    def self.scan(socket_descriptors = nil)
      scan_id_index = {}
      scan_state_index = {}

      Dir.entries("/proc/").each do |pid|
        if File.directory?("/proc/#{pid}/") and /[\d]+/ =~ pid and pid.to_s != ::Process.pid.to_s
          begin
            process_descriptor = ::ProcFS::ProcessDescriptor.parse_proc(pid, socket_descriptors)
            scan_id_index[pid] = process_descriptor
            scan_state_index[process_descriptor.state_hash] = process_descriptor
          rescue
            puts "*** Process #{pid} died while attempting to read its /proc/ entry. ***"
          end
        end
      end

      return ::ProcFS::ProcessList.new(scan_id_index, scan_state_index)
    end

    def initialize(*args)
      super(*args)
      @separator = "\n\n"
    end

  end

end