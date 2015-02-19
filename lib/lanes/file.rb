require "thor"
module LanesCli
  class FileCmd < Thor

    method_option :confirm, :type => :boolean
    desc "push [target] [destination] [LANE]", "Pushes [file] to [destination] on all [LANE] instances "
    def push(target, dest, lane=nil)
      pwd = Dir.pwd
      puts "#{pwd} #{target} #{dest} #{lane}"
      file = "#{pwd}/#{target}"

      servers = AWS.instance.fetchServers(lane)
      servers.sort_by{ |s| s[:lane] }
      puts 'Servers that will receive the file:'
      servers.each{|server|
        puts "\t%{name} (%{lane}) \t %{ip} \t %{id} " % server
      }


      mods = Props.instance.sshMod(lane)
      identity = if mods['identity'] then mods['identity'] else '' end
      puts "Identity file #{mods['identity']} will be used" if identity

      if options[:confirm] then
        puts 'Confirmed via command line. Moving forward with execution..'
        confirm = 'CONFIRM'
      else
        confirm = ask 'Type CONFIRM to begin pushing files:'
      end


      if confirm == 'CONFIRM' then
        servers.each{|server|
          id = if identity then "-i #{identity}" else '' end
          user = if mods['user'] then mods['user'] else 'ec2-user' end
          cmd = "scp #{id} #{file} #{user}@%{ip}:#{dest}" % server
          puts " => Executing: #{cmd}"
          result = system cmd
          if !result then
            puts 'WARNING: Failed on %{ip}' % server
          end
        }
      end

    end
  end
end
