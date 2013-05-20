module ProcFS

  module SocketDescriptor

    class Net

      attr_accessor :state_hash, :inode, :state, :reference_count, :type,
      :remote_address_bytes, :remote_address_quad, :remote_port,
      :local_address_bytes, :local_address_quad, :local_port,
      :tx_queue, :rx_queue, :uid

      def initialize(socket_line = nil)
        parse_socket(socket_line) unless socket_line.nil?
      end

      def ip_decode(hex)
        binary = [hex].pack("H*")
        longs = binary.unpack("L*")
        case longs.length
          when 4 #IPV6 has 4 longs
            [
              longs.take(3).map { |long|
                "%x:%x" % [long >> 16, long & 0xffff]
              }.join(":"),
              [longs[3]].pack("L*").unpack("C*").reverse.join(".")
            ].join(":")
          when 1 #IPV4 has 1 long
            binary.unpack("C*").reverse.join(".")
          else
            "Invalid IP address"
        end
      end

      def parse_socket(socket_line)
        # Format of /proc/net entries
        # # cat /proc/net/tcp
        #   sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode
        #    0: 0100007F:7D00 00000000:0000 0A 00000000:00000000 00:00000000 00000000   997        0 12797597 1 ee54b440 300 0 0 2 -1
        # # cat /proc/net/udp
        #   sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode ref pointer drops
        #   35: 00000000:0323 00000000:0000 07 00000000:00000000 00:00000000 00000000     0        0 3464 2 ee8ce240 0

        socket_decriptor            = socket_line.split
        local_address, local_port   = socket_decriptor[1].split(':')
        remote_address, remote_port = socket_decriptor[2].split(':')
        tx_queue, rx_queue          = socket_decriptor[4].split(':')
        tr, tm_when                 = socket_decriptor[5].split(':')

        # Common socket properties
        @inode                  = socket_decriptor[9]
        @state                  = ::ProcFS::NET_STATES[socket_decriptor[3]]
        @reference_count        = socket_decriptor[10]

        # Network socket porperties
        @remote_address_bytes   = remote_address
        @remote_address_quad    = ip_decode(remote_address)
        @remote_port            = remote_port.to_i(16)
        @local_address_bytes    = local_address
        @local_address_quad     = ip_decode(local_address)
        @local_port             = local_port.to_i(16)
        @tx_queue               = tx_queue
        @rx_queue               = rx_queue
        @uid                    = socket_decriptor[7]
        @state_hash             = generate_state_hash
      end

      def generate_state_hash
        Digest::SHA1.hexdigest(
          [
            @type, @inode, @state, @reference_count, @local_address_bytes,
            @local_port, @remote_address_bytes, @remote_port
          ].join
        )
      end

      def to_s
        "#{type} #{inode} #{state} #{reference_count} #{local_address_quad}:#{local_port} ---> #{remote_address_quad}:#{remote_port}"
      end

    end

  end

end