module ProcFS

  class ProcessDescriptor < ::ProcFS::IdStateListItem

    def self.parse_proc(pid, socket_descriptors = nil)
      path    = "/proc/#{pid}"
      inodes  = parse_socket_inodes(path)
      sockets = socket_descriptors.filter_by_id(inodes) unless socket_descriptors.nil?

      properties = {
        :id             => pid,
        :pid            => pid,
        :cmdline        => read_cmdline(path),
        :socket_inodes  => inodes,
        :sockets        => sockets,
        :stat           => parse_stat(path),
        :statm          => parse_statm(path),
        :oom_adj        => parse_oom_adj(path),
        :oom_score      => parse_oom_score(path)
      }
      process_descriptor = ::ProcFS::ProcessDescriptor.new(properties)
      return process_descriptor
    end

    def self.read_cmdline(path)
      IO.read("#{path}/cmdline").gsub("\0", ' ')
    end

    def self.parse_socket_inodes(path)
      inodes = []
      fd_path = "#{path}/fd/"
      fd = Dir.new(fd_path)
      fd.each do |handle|
        if /[\d]+/ =~ handle
          actual_path = File.readlink(fd_path + handle)
          match = /socket\:\[(?<inode>\d+)\]/.match(actual_path)
          inodes << match[:inode] unless match.nil?
        end
      end
      inodes
    end

    def self.parse_stat(path)
      stat_line = IO.read("#{path}/stat")
      raw_stat = stat_line.split
      stat = {
        :pid          => raw_stat[0],
        :comm         => raw_stat[1],
        :state        => raw_stat[2],
        :ppid         => raw_stat[3],
        :pgrp         => raw_stat[4],
        :session      => raw_stat[5],
        :tty_nr       => raw_stat[6],
        :tpgid        => raw_stat[7],
        :flags        => raw_stat[8],
        :minflt       => raw_stat[9],
        :cminflt      => raw_stat[10],
        :majflt       => raw_stat[11],
        :cmajflt      => raw_stat[12],
        :utime        => raw_stat[13],
        :stime        => raw_stat[14],
        :cutime       => raw_stat[15],
        :cstime       => raw_stat[16],
        :priority     => raw_stat[17],
        :nice         => raw_stat[18],
        :num_threads  => raw_stat[19],
        :itrealvalue  => raw_stat[20],
        :starttime    => raw_stat[21],
        :vsize        => raw_stat[22],
        :rss          => raw_stat[23],
        :rsslim       => raw_stat[24],
        :startcode    => raw_stat[25],
        :endcode      => raw_stat[26],
        :startstack   => raw_stat[27],
        :kstkesp      => raw_stat[28],
        :kstkeip      => raw_stat[29],
        :signal       => raw_stat[30], #
        :blocked      => raw_stat[31], #
        :sigignore    => raw_stat[32], #
        :sigcatch     => raw_stat[33], #
        :wchan        => raw_stat[34],
        :nswap        => raw_stat[35], ##
        :cnswap       => raw_stat[36], ##
        :exit_signal  => raw_stat[37],
        :processor    => raw_stat[38],
        :rt_priority  => raw_stat[39],
        :policy       => raw_stat[40],
        :delayacct_blkio_ticks => raw_stat[41],
        :guest_time   => raw_stat[42],
        :cguest_time  => raw_stat[43]
      }
      return ::ProcFS::PropertyBag.new(stat)
    end
    
    def self.parse_statm(path)
      statm_line = IO.read("#{path}/statm")
      raw_statm = statm_line.split
      statm = {
        :size     => raw_statm[0],
        :resident => raw_statm[1],
        :share    => raw_statm[2],
        :text     => raw_statm[3],
        :lib      => raw_statm[4],
        :data     => raw_statm[5],
        :dt       => raw_statm[6]
      }
      return ::ProcFS::PropertyBag.new(statm)
    end

    def self.parse_oom_adj(path)
      IO.read("#{path}/oom_adj").chomp
    end

    def self.parse_oom_score(path)
      IO.read("#{path}/oom_score").chomp
    end

    def get_state_for_hash
      state_data = ""
      state_data += statm.values.join unless statm.nil?
      state_data += sockets.state_hash unless sockets.nil?
      state_data
    end

  end

end