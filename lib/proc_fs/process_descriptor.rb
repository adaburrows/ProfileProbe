module ProcFS

  class ProcessDescriptor

    attr_accessor :state_hash, :pid, :path, :cmdline, :socket_inodes, :sockets, :stat, :statm, :oom_adj, :oom_score

    def initialize(pid = nil, socket_descriptors = nil)
      @path = "/proc/#{pid}"
      parse_pid(pid, socket_descriptors) unless pid.nil?
    end

    def parse_pid(pid, socket_descriptors = nil)
      @pid            = pid
      @cmdline        = read_cmdline(pid)
      @socket_inodes  = parse_socket_inodes(pid)
      @sockets        = socket_descriptors.filter_on_inode(@socket_inodes) unless socket_descriptors.nil?
      @stat           = parse_stat(pid)
      @statm          = parse_statm(pid)
      @oom_adj        = parse_oom_adj(pid)
      @oom_score      = parse_oom_score(pid)
      @state_hash     = generate_state_hash
    end

    def read_cmdline(pid)
      IO.read("#{path}/cmdline").gsub("\0", ' ')
    end

    def parse_socket_inodes(pid)
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

    def parse_stat(pid)
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
    end
    
    def parse_statm(pid)
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
    end

    def parse_oom_adj(pid)
      IO.read("#{path}/oom_adj").chomp
    end

    def parse_oom_score(pid)
      IO.read("#{path}/oom_score").chomp
    end

    def generate_state_hash
      Digest::SHA1.hexdigest([@pid, @statm, @sockets.state_hash].flatten.join)
    end

    def to_s
      "== #{pid} ==\n#{cmdline}\n" +
      "-- Memory --\nSize: #{statm[:size]} Resident: #{statm[:resident]} Share: #{statm[:share]} Text: #{statm[:text]} Lib: #{statm[:lib]} Data: #{statm[:data]} Dt: #{statm[:dt]}\n" +
      "-- SOCKETS --\n#{@sockets}\n-- OOM --\nScore: #{oom_score} Adjustment: #{oom_adj}"
    end

  end

end