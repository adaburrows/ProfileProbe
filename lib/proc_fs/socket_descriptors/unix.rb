module ProcFS

  module SocketDescriptor

    class Unix < ::ProcFS::IdStateListItem

      attr_accessor :type

      def self.parse_socket(socket_line)
        # Format of /proc/net entries
        # # cat /proc/net/unix
        # Num       RefCount Protocol Flags    Type St Inode Path
        # ee9c5e00: 0000000A 00000000 00000000 0002 01  3352 /dev/log

        socket_descriptor = socket_line.split

        properties = {
          :id               => socket_descriptor[6],

          # Common socket properties
          :inode            => socket_descriptor[6],
          :state            => ::ProcFS::NET_STATES[socket_descriptor[5]],
          :reference_count  => socket_descriptor[1],

          # Unix socket specific properties
          :path             => socket_descriptor[7]
        }

        return ::ProcFS::SocketDescriptor::Unix.new(properties)
      end

      def -(rhs)
        list_item_delta = super(rhs)
        unless list_item_delta.nil?
          list_item_delta = merge list_item_delta
        end
        list_item_delta
      end

      def to_s
        "#{type} #{inode} #{state} #{reference_count} #{path}"
      end

    end

  end

end