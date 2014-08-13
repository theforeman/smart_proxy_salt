module Proxy::Salt
  class Autosign

    def initialize
      @autosign_file = Proxy::Salt::Plugin.settings.autosign_file
    end

    def create host
      FileUtils.touch(@autosign_file) unless File.exist?(@autosign_file)

      autosign = open(@autosign_file, File::RDWR)

      found = false
      autosign.each_line { |line| found = true if line.chomp == host }
      autosign.puts host if found == false
      autosign.close

      logger.info "Added #{host} to autosign"
    end

    def remove host
      raise "No such file #{@autosign_file}" unless File.exists?(@autosign_file)

      found = false
      entries = open(@autosign_file, File::RDONLY).readlines.collect do |l|
        if l.chomp != host
          l
        else
          found = true
          nil
        end
      end.uniq.compact
      if found
        autosign = open(@autosign_file, File::TRUNC|File::RDWR)
        autosign.write entries.join("\n")
        autosign.write "\n"
        autosign.close
        logger.info "Removed #{host} from autosign"
      else
        logger.info "Attempt to remove nonexistant client autosign for #{host}"
        raise Proxy::Salt::NotFound, "Attempt to remove nonexistant client autosign for #{host}"
      end
    end
  end
end

