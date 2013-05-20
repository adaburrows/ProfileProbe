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

  class SocketList

    attr_accessor :types, :net_path, :sockets, :state_hash

    def initialize(types = ['tcp', 'tcp6', 'udp', 'udp6', 'unix'], sockets = nil)
      @types = types
      @net_path = "/proc/net"
      if sockets.nil?
        @sockets = {}
        @types.each do |type|
          @sockets.merge! parse_proc_net(type)
        end
        @state_hash = generate_state_hash
      else
        @sockets = sockets
      end
    end

    def proc_path(type = 'tcp')
      "#{net_path}/#{type}"
    end

    def parse_proc_net(type)
      sockets = {}
      File.readlines(proc_path(type))[1..-1].each do |line|
        case type
          when "unix"
            socket = ::ProcFS::SocketDescriptor::Unix.new(line)
          else
            socket = ::ProcFS::SocketDescriptor::Net.new(line)
        end
        socket.type = type
        sockets[socket.state_hash] = socket
      end
      return sockets
    end

    def filter_on_inode(inode_list)
      filtered_sockets = {}
      @sockets.each do |h, s|
        inode_list.each do |inode|
          filtered_sockets[h] = s if s.inode == inode
        end
      end
      SocketList.new(@type, filtered_sockets)
    end

    def -(rhs_sockets)
      rhs_hashes = rhs_sockets.keys
      lhs_hashes = @sockets.keys

      lhs_only_hashes = lhs_hashes - rhs_hashes

      lhs_only_sockets = @sockets.select { |h,s| lhs_only_hashes.member? h }

      SocketList.new(@type, lhs_only_sockets)
    end

    def empty?
      @sockets.empty?
    end

    def generate_state_hash
      Digest::SHA1.hexdigest(@sockets.keys.join)
    end

    def to_s
      socket_strings = []
      @sockets.each { |h, s| socket_strings << s.to_s }
      socket_strings.join("\n")
    end

  end

end