module ProcFS

  module SocketDescriptor

    class Unix

      attr_accessor :state_hash, :inode, :state, :reference_count, :type, :path

      def initialize(socket_line = nil)
        parse_socket(socket_line) unless socket_line.nil?
      end

      def parse_socket(socket_line)
        # Format of /proc/net entries
        # # cat /proc/net/unix
        # Num       RefCount Protocol Flags    Type St Inode Path
        # ee9c5e00: 0000000A 00000000 00000000 0002 01  3352 /dev/log

        socket_decriptor  = socket_line.split

        # Common socket properties
        @inode            = socket_decriptor[6]
        @state            = ::ProcFS::NET_STATES[socket_decriptor[5]]
        @reference_count  = socket_decriptor[1]

        # Unix socket specific properties
        @path             = socket_decriptor[7]

        @state_hash       = generate_state_hash

      end

      def generate_state_hash
        Digest::SHA1.hexdigest(
          [
            @type, @inode, @state, @reference_count
          ].join
        )
      end

      def to_s
        "#{type} #{inode} #{state} #{reference_count} #{path} "
      end

    end

  end

end