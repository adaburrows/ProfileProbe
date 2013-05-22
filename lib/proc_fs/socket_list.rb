module ProcFS

  NET_STATES = {
    '00' => 'UNKNOWN',  # Bad state ... Impossible to achieve ...
    'FF' => 'UNKNOWN',  # Bad state ... Impossible to achieve ...
    '01' => 'ESTABLISHED',
    '02' => 'SYN_SENT',
    '03' => 'SYN_RECV',
    '04' => 'FIN_WAIT1',
    '05' => 'FIN_WAIT2',
    '06' => 'TIME_WAIT',
    '07' => 'CLOSE',
    '08' => 'CLOSE_WAIT',
    '09' => 'LAST_ACK',
    '0A' => 'LISTEN',
    '0B' => 'CLOSING'
  }

  SOCKET_TYPES = ['tcp', 'tcp6', 'udp', 'udp6', 'unix']

  class SocketList  < ::ProcFS::IdStateList

    def self.scan
      scan_id_index = {}
      scan_state_index = {}

      ::ProcFS::SOCKET_TYPES.each do |type|
        File.readlines("/proc/net/#{type}")[1..-1].each do |line|
          case type
            when "unix"
              socket_descriptor = ::ProcFS::SocketDescriptor::Unix.parse_socket(line)
            else
              socket_descriptor = ::ProcFS::SocketDescriptor::Net.parse_socket(line)
          end
          socket_descriptor.type = type

          scan_id_index[socket_descriptor.id] = socket_descriptor
          scan_state_index[socket_descriptor.state_hash] = socket_descriptor
        end
      end

      return ::ProcFS::SocketList.new(scan_id_index, scan_state_index)
    end

  end

end