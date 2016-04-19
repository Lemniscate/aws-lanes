require 'singleton'

class AWS
  include Singleton

  def initialize
    @conn = Awscli::Connection.new.request_ec2('us-west-2')
  end

  # Fetch any servers in a given lane
  def fetchServers(lane=nil)
    servers = []

    @conn.servers.each{ |server|
      s = {
          :ip => server.public_ip_address,
          :lane => server.tags['Lane'],
          :name => server.tags['Name'],
          :id => server.id
      }
      if s[:ip]
        if lane == nil or lane == s[:lane]
          servers.push s
        end
      end
    };

    servers.sort_by!{ |s| [s[:lane] ? s[:lane] : "zzz", s[:name]] }

    return servers
  end
end