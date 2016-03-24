require 'net/ssh'
require 'lanes/version'
require 'lanes/aws'
require 'lanes/props'
require 'lanes/file'
require 'thor'
require 'yaml'
require 'awscli'
require 'rest_client'

module LanesCli
  class Lanes < Thor

    desc "switch [profile]", "Switches AWS profiles (e.g. ~/.lanes/lanes.yml entry)"
    def switch(profile)
      path = ENV['HOME'] + '/.lanes/lanes.yml'
      data = YAML.load_file path
      data["profile"] = profile
      File.open(path, 'w') { |f| YAML.dump(data, f) }

      puts "Switched to #{profile}"
    end

    desc "list [LANE]", "Lists all servers name + ip + Instance ID, optionally filtered by lane 2"
    def list(lane=nil)
      servers = AWS.instance.fetchServers(lane)
      servers.sort_by{ |s| [s[:lane], s[:name]] }
      servers.each{|server|
        puts "\t%{name} (%{lane}) \t %{ip} \t %{id} " % server
      }
    end

    desc "ssh [LANE]", "Lists all servers name + ip + Instance ID, optionally filtered by lane, and prompts which one for ssh"
    def ssh(lane=nil)
      chosen = chooseServer(lane)
      if chosen != nil
        mods = Props.instance.sshMod(chosen[:lane])
        identity = "-i #{mods['identity']}" if mods['identity']
        tunnels = "-L#{mods['tunnel']}" if mods['tunnel']
        tunnels = mods['tunnels'].map{|tunnel| "-L#{tunnel}"}.join(' ') if mods['tunnels']
        user = mods['user'] ? mods['user'] : 'ec2-user'
        cmd = "ssh #{user}@%{ip} #{identity} #{tunnels}" % chosen
        exec cmd
      else
        puts 'Canceled'
      end
    end


    method_option :cmd, :type => :array
    method_option :urlConfirm, :type => :string
    method_option :urlConfirmTimeout, :type => :numeric
    method_option :urlConfirmDelay, :type => :numeric
    method_option :v, :type => :boolean
    method_option :confirm, :type => :boolean
    desc "sh [LANE] ", "Executes a command on all machines with support for confirming an endpoint is available after"
    def sh(lane)
      servers = AWS.instance.fetchServers(lane)
      servers.sort_by{ |s| s[:ip] }

      puts "Available Servers: "
      servers.each_with_index {|server|
        puts "\t%{name} (%{lane}) \t %{ip} \t %{id} " % server
      }


      mods = Props.instance.sshMod(lane)
      identity = if mods['identity'] then mods['identity'] else '' end
      puts "Identity file #{mods['identity']} will be used" if identity

      command = options[:cmd].join(' ')
      if options[:confirm] then
        puts "Confirmed via command line. Moving forward with execution of \"#{command}\" on these machines:"
        confirm = 'CONFIRM'
      else
        confirm = ask "Type CONFIRM to execute \"#{command} \" on these machines:"
      end

      if confirm == 'CONFIRM' then
        servers.each{ |server|
          user = if mods['user'] then mods['user'] else 'ec2-user' end
          Net::SSH.start( server[:ip], user,
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
          confirmDelay = (options[:urlConfirmDelay] or 5)
          confirmTimeout = (options[:urlConfirmTimeout] or 30);
          startTime = Time.new.to_i

          # we better sleep for a few, otherwise the shutdown won't have executed
          puts "Sleeping for #{confirmDelay} seconds, then trying the confirmation endpoint for #{confirmTimeout} seconds..."
          sleep confirmDelay
          while Time.new.to_i - startTime < confirmTimeout && servers.length > 0 do
            servers.each_with_index{ |server, index|
              begin
                res = RestClient.get (confirmPath % server)
                if res.code >= 200 && res.code < 300 then
                  puts "\t => #{server[:ip]} responded with #{res.code}"
                  servers.delete_at(index)
                else
                  puts "\t XX #{server[:ip]} responded with #{res.code}" if options[:v]
                end
              rescue => e
                puts "\t XX #{server[:ip]} connection failed: #{e}" if options[:v]
              end
            }

            sleep 5 if servers.length > 0
            puts "\t => #{servers.length} server(s) remaining..." if servers.length > 0
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

    desc 'file SUBCOMMAND ...ARGS', 'Push / pull files'
    subcommand 'file', LanesCli::FileCmd


    no_commands{
      def chooseServer(lane=nil)
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

  # load the Lanes settings file
  lanes_config = YAML.load_file( ENV['HOME'] + '/.lanes/lanes.yml')
  profile = lanes_config['profile']
  proflie_config_path = ENV['HOME'] + "/.lanes/#{profile}.yml"

  if File.exist? proflie_config_path
    # hijack the AwsCli file variable
    ENV['AWSCLI_CONFIG_FILE']=proflie_config_path

    # Populate our properties singleton as well
    settings = YAML.load_file proflie_config_path

    Props.instance.set(settings)

    # TODO close the connection in the singleton
  end

end
