require "lanes/version"
require "lanes/aws"
require "lanes/props"
require "thor"
require 'yaml'
require 'AwsCli'
require 'AwsCli/CLI/EC2/Instances'
require 'rest_client'

class Lanes < Thor
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
    if chosen != nil
      mods = Props.instance.sshMod(chosen[:lane])
      identity = if mods['identity'] then '-i ' + mods['identity'] else '' end
      tunnel = if mods['tunnel'] then '-L' + mods['tunnel'] else '' end

      cmd = "ssh ec2-user@%{ip} #{identity} #{tunnel}" % chosen
      exec cmd
    else
      puts 'Canceled'
    end
  end

  method_option :cmd, :type => :array
  method_option :urlConfirm, :type => :string
  method_option :urlConfirmTimeout, :type => :numeric
  desc "exec [LANE] ", "Executes a command on all machines with support for confirming an endpoint is available after"
  def exec(lane)
    servers = AWS.instance.fetchServers(lane)
    servers.sort_by{ |s| s[:ip] }

    puts "Available Servers: "
    servers.each_with_index {|server|
      puts "\t%{name} (%{lane}) \t %{ip} \t %{id} " % server
    }


    mods = Props.instance.sshMod(lane)
    identity = if mods['identity'] then mods['identity'] else '' end
    puts "Identity file #{mods['identity']} will be used" if identity

    if options[:confirm] then
      puts "Confirmed via command line. Moving forward with execution"
    else
      command = options[:cmd].join(' ')
      confirm = ask "Type CONFIRM to execute \"#{command} \" on these machines:"
      if confirm == 'CONFIRM' then
        servers.each{ |server|
          Net::SSH.start( server[:ip], 'ec2-user',
            :keys => [identity],
            # :verbose => :debug,
            :encryption => "blowfish-cbc",
            :compression => "zlib",
            :host_key => "ssh-rsa") do |ssh|
              puts "Executing on %{name} ( %{ip} ):\t #{command} \n" % server
              stdout = ''
              ssh.exec!(command) do |channel, stream, data|
                stdout << data
              end
              puts "Completed. %{name}\n\tOutput: #{stdout}\n\n " % server
            end
        }


        confirmPath = options[:urlConfirm]
        if confirmPath != nil then
          confirmTimeout = (options[:urlConfirmTimeout] or 30) * 1000;
          startTime = Time.new.to_i;
          while Time.new.to_i - startTime < confirmTimeout && servers.length > 0 do
            servers.each_with_index{ |server, index|
              res = RestClient.get (confirmPath % server)
              if res.code >= 200 && res.code < 300 then
                puts "\t => #{server[:ip]} responded with #{res.code}"
                servers.delete_at(index)
              else
                puts "\t XX #{server[:ip]} responded with #{res.code}"
              end
            }

            sleep 5 if servers.length > 0
          end

          if servers.length == 0 then
            puts "Successfully confirmed endpoints responded with a 2XX"
          else
            puts "The following server(s) did not respond with a 2XX:"
            servers.each{ |server|
              puts "\t%{name} (%{lane}) \t %{ip} \t %{id} " % server
            }
          end
        end
      else
        puts 'Aborted!'
        exit 1
      end
    end
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
      chosen = servers[ choice.to_i - 1 ] if choice != ''
    end
  }
end

if ENV['RUBYMINE'] != nil
  # load the Lanes settings file
  config = YAML.load_file( ENV['HOME'] + '/.lanes/lanes.yml')
  profile = config['profile']

  # hijack the AwsCli file variable
  ENV['AWSCLI_CONFIG_FILE']="~/.lanes/#{profile}.yml"

  # Populate our properties singleton as well
  settings = YAML.load_file( ENV['HOME'] + "/.lanes/#{profile}.yml")

  Props.instance.set(settings)
  Lanes.start( ENV['RUBYMINE'].split(' ') )
  # TODO close the connection in the singleton
end

