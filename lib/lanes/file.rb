require "thor"
module LanesCli
  class FileCmd < Thor
    desc "push [target] [destination] [LANE]", "Pushes [file] to [destination] on all [LANE] instances "
    def push(target, dest, lane=nil)
      pwd = Dir.pwd
      puts "#{pwd} #{target} #{dest} #{lane}"

      file = File.open("#{pwd}/#{target}", "r")
      contents = file.read
      puts contents

      servers = AWS.instance.fetchServers(lane)
      servers.sort_by{ |s| s[:lane] }
      servers.each{|server|
        puts "\t%{name} (%{lane}) \t %{ip} \t %{id} " % server
      }
    end
  end
end
