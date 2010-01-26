# class Repository represents a software repository

require 'resolvable'

class Repository

  attr_accessor   :id,
    :name,
    :enabled,
    :autorefresh,
    :url,
    :priority,
    :keep_packages

  def initialize(id, name, enabled)
    @id = id
    @name = name
    @enabled = enabled

    # set defaults
    @url = ''
    @priority = 99
    @autorefresh = true
    @keep_packages = false
  end

  def self.find(what)
    repositories = Array.new

    Resolvable.execute('GetRepoList', 'NONE', 'RepoDetail') { |id, name, enabled|
      Rails.logger.debug "RepoDetail signal received: #{id}, #{name}, #{enabled}"

      if what == :all || id == what
        repo = Repository.new(id, name, enabled)
        # read other attributes directly from *.repo file,
        # because PackageKit doesn't have API for that
        repo.read_file

        repositories << repo
      end
    }

    return repositories
  end

  # read autorefresh, URL, keep_packages and priority directly from *.repo file
  def read_file
    Rails.logger.debug "Reading repofile: /etc/zypp/repos.d/#{@id}.repo"
    file = File.new "/etc/zypp/repos.d/#{@id}.repo"

    while line = file.gets
      # remove comments
      line.match /^([^#].*)#.*$/
      l = $1

      if !l.blank?
        l.match /^[ \t]*([^=].*)[ \t]*=[ \t]*(.*)[ \t]*$/

        key = $1
        value = $2

        if !key.blank? && !value.blank?
          Rails.logger.debug "Read key: #{key}, value: #{value}"

          case key
            when 'autorefresh'
              @autorefresh = (value == 'true' || value = '1')
            when 'keeppackages'
              @keep_packages = (value == 'true' || value = '1')
            when 'priority'
              if value.match /'[0-9]+'/
                @priority = value.to_i
              else
                Rails.logger.error "Non-number value for priority key: #{value}"
              end
            when 'baseurl'
              @url = value
            # other values are returned by PackageKit, just ignore them
          end
        end

      end
    end
  end

  def self.exists?(id)
    self.find(:all).any? {|repo|
      repo.id == id
    }
  end

  def save
    return false if @id.blank?

    # create a new repository if it does not exist yet
    if !Repository.exists?(@id)
      Rails.logger.info "Adding a new repository '#{@id}'"
      Resolvable.execute('RepoSetData', [@id, 'add', @url], 'RepoDetail') { |id, name, enabled|
        Rails.logger.debug "RepoDetail signal received: #{id}, #{name}, #{enabled}"
      }
    else
      Rails.logger.info "Modifying repository '#{@id}'"
    end

    # TODO: save all repository properties here...
    # FIXME: 'RepoDetail' signal handler is not needed here, remove it
    Resolvable.execute('RepoEnable', [@id, @enabled], 'RepoDetail') { |id, name, enabled|
      Rails.logger.debug "RepoDetail signal received: #{id}, #{name}, #{enabled}"
    }

    # set priority
    # FIXME: 'RepoDetail' signal handler is not needed here, remove it
    Resolvable.execute('RepoSetData', [@id, 'prio', @priority.to_s], 'RepoDetail') { |id, name, enabled|
      Rails.logger.debug "RepoDetail signal received: #{id}, #{name}, #{enabled}"
    }

    # set autorefresh
    # FIXME: 'RepoDetail' signal handler is not needed here, remove it
    Resolvable.execute('RepoSetData', [@id, 'refresh', @autorefresh.to_s], 'RepoDetail') { |id, name, enabled|
      Rails.logger.debug "RepoDetail signal received: #{id}, #{name}, #{enabled}"
    }

    Resolvable.execute('RepoSetData', [@id, 'name', @name.to_s], 'RepoDetail') { |id, name, enabled|
      Rails.logger.debug "RepoDetail signal received: #{id}, #{name}, #{enabled}"
    }

    Resolvable.execute('RepoSetData', [@id, 'url', @url], 'RepoDetail') { |id, name, enabled|
      Rails.logger.debug "RepoDetail signal received: #{id}, #{name}, #{enabled}"
    }

    return true
  end

  def destroy
    return false if @id.blank?

    # FIXME: 'RepoDetail' signal handler is not needed here, remove it
    Resolvable.execute('RepoSetData', [@id, 'remove', 'NONE'], 'RepoDetail') { |id, name, enabled|
      Rails.logger.debug "RepoDetail signal received: #{id}, #{name}, #{enabled}"
    }
    
    return true
  end

  def to_xml(options = {})
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.tag! :repository do
      xml.tag!(:id, @id)
      xml.tag!(:name, @name)
      xml.tag!(:url, @url)
      xml.tag!(:enabled, @enabled, {:type => "boolean"})
      xml.tag!(:autorefresh, @autorefresh, {:type => "boolean"})
      xml.tag!(:keep_packages, @keep_packages, {:type => "boolean"})
      xml.tag!(:priority, @priority, {:type => "integer"})
    end
  end

  def to_json(options = {})
    hash = Hash.from_xml(to_xml(options))
    return hash.to_json
  end

end
