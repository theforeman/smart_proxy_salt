module Proxy::Salt
  extend ::Proxy::Log
  extend ::Proxy::Util

  class << self

    # Move these to a util thingy later
    def shell_command(cmd, wait = true)
      begin
        c = popen(cmd)
        unless wait
          Process.detach(c.pid)
          return 0
        end
        Process.wait(c.pid)
      rescue Exception => e
        logger.error("Exception '#{e}' when executing '#{cmd}'")
        return false
      end
      logger.warn("Non-null exit code when executing '#{cmd}'") if $?.exitstatus != 0
      $?.exitstatus == 0
    end

    def popen(cmd)
      # 1.8.7 note: this assumes that cli options are space-separated
      cmd = cmd.join(' ') unless RUBY_VERSION > '1.8.7'
      logger.debug("about to execute: #{cmd}")
      IO.popen(cmd)
    end

    def autosign_file
      Proxy::Salt::Plugin.settings.autosign_file
    end

    def autosign_create host
      FileUtils.touch(autosign_file) unless File.exist?(autosign_file)

      autosign = open(autosign_file, File::RDWR)

      found = false
      autosign.each_line { |line| found = true if line.chomp == host }
      autosign.puts host if found == false
      autosign.close

      result = {:message => "Added #{host} to autosign"}
      logger.info result[:message]
      result
    end

    def autosign_remove host
      raise "No such file #{autosign_file}" unless File.exists?(autosign_file)

      found = false
      entries = open(autosign_file, File::RDONLY).readlines.collect do |l|
        if l.chomp != host
          l
        else
          found = true
          nil
        end
      end.uniq.compact
      if found
        autosign = open(autosign_file, File::TRUNC|File::RDWR)
        autosign.write entries.join("\n")
        autosign.write "\n"
        autosign.close
        result = {:message => "Removed #{host} from autosign"}
        logger.info result[:message]
        result
      else
        logger.info "Attempt to remove nonexistant client autosign for #{host}"
        raise Proxy::Salt::NotFound, "Attempt to remove nonexistant client autosign for #{host}"
      end
    end

    def highstate host
      cmd = [which("sudo"), "-u", Proxy::Salt::Plugin.settings.salt_command_user, which("salt"), "--async", "'#{escape_for_shell(host)}'", "state.highstate"]
      logger.info "Will run state.highstate for #{host}. Full command: #{cmd.join(" ")}"
      shell_command(cmd)
    end

    def key_delete host
      cmd = [which("sudo"), "-u", Proxy::Salt::Plugin.settings.salt_command_user, which("salt-key"), '--yes', '-d', escape_for_shell(host)]
      shell_command(cmd)
    end
  end
end
