require 'singleton'

class Props
  include Singleton

  def initialize
    @props = {}
  end

  def get(key)
    @props[key]
  end

  def set(props)
    @props = props
    @props.delete 'aws_access_key_id'
    @props.delete 'aws_secret_access_key'

    # puts @props
  end

  def sshMod(server_name)
    ssh = @props['ssh']
    if ssh then
      mods = ssh['mods']
      if mods then
        p = mods[server_name]
        return p
      end
    end
  end

end