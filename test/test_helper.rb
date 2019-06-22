require 'test/unit'
$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require 'smart_proxy_for_testing'

# create log directory and log file in our (not smart-proxy) directory
logdir = File.join(File.dirname(__FILE__), '..', 'logs')
logfile = "#{logdir}/test.log"
FileUtils.mkdir_p(logdir) unless File.exist?(logdir)
FileUtils.touch(logfile) unless File.exist?(logfile)
