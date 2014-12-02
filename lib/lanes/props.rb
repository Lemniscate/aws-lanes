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

  def sshMod(lane)
    ssh = @props['ssh']
    if ssh then
      mods = ssh['mods']
      if mods then
        p = mods[lane]
        return p
      end
    end
  end

end