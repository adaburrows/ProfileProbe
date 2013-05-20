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

  class SocketList

    attr_accessor :net_path, :id_index, :state_index, :state_hash

    def self.scan
      scan_id_index = {}
      scan_state_index = {}

      ::ProcFS::SOCKET_TYPES.each do |type|
        File.readlines("/proc/net/#{type}")[1..-1].each do |line|
          case type
            when "unix"
              socket_descriptor = ::ProcFS::SocketDescriptor::Unix.new(line)
            else
              socket_descriptor = ::ProcFS::SocketDescriptor::Net.new(line)
          end
          socket_descriptor.type = type

          scan_id_index[socket_descriptor.inode] = socket_descriptor
          scan_state_index[socket_descriptor.state_hash] = socket_descriptor
        end
      end

      return SocketList.new(scan_id_index, scan_state_index)
    end


    def initialize(passthrough_id_index = {}, passthrough_state_index = {})
      @net_path = "/proc/net"
      @id_index = passthrough_id_index
      @state_index = passthrough_state_index
      @state_hash = generate_state_hash
    end

    def proc_path(type = 'tcp')
      "#{net_path}/#{type}"
    end

    def filter_on_inode(inode_list)
      filtered_id_index = {}
      filtered_state_index = {}

      inode_list.each do |i|
        socket_descriptor = @id_index[i]
        unless socket_descriptor.nil?
          filtered_id_index[socket_descriptor.inode] = socket_descriptor
          filtered_state_index[socket_descriptor.state_hash] = socket_descriptor
        end
      end

      return SocketList.new(filtered_id_index, filtered_state_index)
    end

    def diff_ids(rhs_socket_list)
      delta_id_index = {}
      delta_state_index = {}

      rhs_ids = rhs_socket_list.id_index.keys
      lhs_ids = @id_index.keys

      delta_ids = lhs_ids - rhs_ids

      delta_ids.each do |inode|
        socket_descriptor = @id_index[inode]
        delta_id_index[inode] = socket_descriptor
        delta_state_index[socket_descriptor.state_hash] = socket_descriptor
      end

      return SocketList.new(delta_id_index, delta_state_index)
    end

    def diff_states(rhs_socket_list)
      delta_id_index = {}
      delta_state_index = {}

      rhs_state_hashes = rhs_socket_list.state_index.keys
      lhs_state_hashes = @state_index.keys

      delta_state_hashes = lhs_state_hashes - rhs_state_hashes

      delta_state_hashes.each do |hash|
        socket_descriptor = @state_index[hash]
        delta_id_index[socket_descriptor.inode] = socket_descriptor
        delta_state_index[hash] = socket_descriptor
      end

      return SocketList.new(delta_id_index, delta_state_index)
    end

    def empty?
      @id_index.empty?
    end

    def generate_state_hash
      ::Digest::MD5.hexdigest(@state_index.keys.join)
    end

    def to_s
      socket_strings = []
      @id_index.each { |id, s| socket_strings << s.to_s }
      socket_strings.join("\n")
    end

  end

end