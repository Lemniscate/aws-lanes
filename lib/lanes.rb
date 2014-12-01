require "lanes/version"
require "lanes/aws"
require "lanes/props"
require "thor"
require 'yaml'
require 'AwsCli'
require 'AwsCli/CLI/EC2/Instances'

class Lanes2 < Thor
  desc "list [LANE]", "Lists all servers name + ip + Instance ID, optionally filtered by lane 2"
  def list(lane=nil)
    servers = AWS.instance.fetchServers(lane)
    servers.sort_by{ |s| s[:lane] }
    servers.each{|server|
      puts "\t%{name} (%{lane}) \t %{ip} \t %{id} " % server
    }
  end

  desc "ssh [LANE]", "Lists all servers name + ip + Instance ID, optionally filtered by lane, and prompts which one for ssh"
  def ssh(lane=nil)
    chosen = chooseServer(lane)
    puts chosen
    mods = Props.instance.sshMod(chosen[:name])
    identity = if mods['identity'] then '-i ' + mods['identity'] else '' end
    tunnel = if mods['tunnel'] then '-L' + mods['tunnel'] else '' end

    cmd = "ssh ec2-user@%{ip} #{identity} #{tunnel}" % chosen
    exec cmd
  end


  no_commands{
    def chooseServer(lane=nul)
      servers = AWS.instance.fetchServers(lane)
      servers.sort_by{ |s| s[:lane] }

      puts "Available Servers: "
      servers.each_with_index {|server, index|
        i = index + 1
        puts "\t#{i}) %{name} (%{lane}) \t %{ip} \t %{id} " % server
      }

      choice = ask "Which server: "
      chosen = servers[ choice.to_i - 1]
      return chosen
    end
  }
end

# # load the Lanes settings file
# config = YAML.load_file( ENV['HOME'] + '/.lanes/lanes.yml')
# profile = config['profile']
#
# # hijack the AwsCli file variable
# ENV['AWSCLI_CONFIG_FILE']="~/.lanes/#{profile}.yml"
#
# # Populate our properties singleton as well
# settings = YAML.load_file( ENV['HOME'] + "/.lanes/#{profile}.yml")
#
# Props.instance.set(settings)
# Lanes.start(ARGV)
# # TODO close the connection in the singleton


