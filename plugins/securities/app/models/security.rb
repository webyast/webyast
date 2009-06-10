class Security #< ActiveRecord::Base
  require "scr"

#  validates_inclusion_of :firewall, :firewall_after_startup, :ssh, :in => [true, false, nil]
attr_reader     :firewall,
    :firewall_after_startup,
    :ssh



  public

  def initialize
    @firewall
    @firewall_after_startup
    @ssh
    @scr = Scr.instance
  end

  def update
    @firewall = firewall?
    @firewall_after_startup = firewall_after_startup?
    @ssh = ssh?
  end

  def write(a, b, c) #(a=firewall?, ..)
    @firewall = firewall(a)
    @firewall_after_startup = firewall_after_startup(b)
    @ssh = ssh(c)
  end

  def to_xml(options = {})
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.security do
      xml.tag!(:ssh, @ssh, {:type => "boolean"})
      xml.tag!(:firewall, @firewall, {:type => "boolean"})
      xml.tag!(:firewall_after_startup, @firewall_after_startup, {:type => "boolean"})
    end
  end

  def to_json(options = {})
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

#  private
  def firewall?
    cmd = @scr.execute(["/sbin/rcSuSEfirewall2", "status"])
    lines = cmd[:stdout].split "\n"
    lines.each do |l|
      if l.length > 0
        if l.include? "running"
          return true
        elsif l.include? "unused"
          return false
        end
      end
    end
    return nil
  end

  def firewall_after_startup?
    cmd = @scr.execute(["/sbin/yast2", "firewall", "startup", "show"])
    lines = cmd[:stderr].split "\n"
    lines.each do |l|
      if l.length > 0
        if l.include? "enabled"
          return true
        elsif l.include? "manual"
          return false
        end
      end
    end
    return nil
  end

  def ssh?
    cmd = @scr.execute(["/usr/sbin/rcsshd", "status"])
    lines = cmd[:stdout].split "\n"
    lines.each do |l|
      if l.length > 0
        if l.include? "running"
          return true
        elsif l.include? "unused"
          return false
        end
      end
    end
    return nil
  end

  # returns true for success and false for failure
  def firewall(param)
    if param # == true   # start firewall
      action = "restart"
    else #if param == false        # stop firewall
      action = "stop"
    end
    cmd = @scr.execute(["/sbin/rcSuSEfirewall2", "#{action}"])
    lines = cmd[:stdout].split "\n"
    lines.each do |l|
      if l.length > 0
        if l.include? "done"
          return param
        end #FIXME else raise ..
      end
    end
  end

  # returns true for success and false for failure
  def firewall_after_startup(param)
    if param    # enable
      action = "atboot"
      verify = "Enabling"
    else        # disable
      action = "manual"
      verify = "Removing"
    end
    cmd = @scr.execute(["/sbin/yast2", "firewall", "startup", "#{action}"])
    lines = cmd[:stderr].split "\n"
    lines.each do |l|
      if l.length > 0
        if l.include? "#{verify}"
          return param
        end #FIXME else raise ..
      end
    end
  end

  # returns true for success and false for failure
  def ssh(param)
    if param    # start sshd
      action = "restart"
    else        # stop sshd
      action = "stop"
    end
    cmd = @scr.execute(["/usr/sbin/rcsshd", "#{action}"])
    lines = cmd[:stdout].split "\n"
    lines.each do |l|
      if l.length > 0
        if l.include? "done"
          return param
        end #FIXME else raise ..
      end
    end
  end
end
