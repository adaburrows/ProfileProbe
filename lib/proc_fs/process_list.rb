module ProcFS

  class ProcessList < ::ProcFS::IdStateList

    def self.scan(socket_descriptors = nil)
      scan_id_index = {}
      scan_state_index = {}

      Dir.entries("/proc/").each do |pid|
        if File.directory?("/proc/#{pid}/") and /[\d]+/ =~ pid and pid.to_s != ::Process.pid.to_s
          # begin
            process_descriptor = ::ProcFS::ProcessDescriptor.new(pid, socket_descriptors)
            scan_id_index[pid] = process_descriptor
            scan_state_index[process_descriptor.state_hash] = process_descriptor
          # rescue
          #   puts "Process #{pid} died while attempting to read its /proc/ entry."
          # end
        end
      end

      return ProcessList.new(scan_id_index, scan_state_index)
    end

    def initialize(passthrough_id_index = {}, passthrough_state_index = {})
      super
    end

    def to_s
      process_strings = []
      @id_index.each { |id, process_descriptor| process_strings << process_descriptor.to_s }
      process_strings.join("\n\n")
    end

    def get_new_instance(passthrough_id_index = {}, passthrough_state_index = {})
      ProcessList.new(passthrough_id_index, passthrough_state_index)
    end

  end

end