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
        repositories << Repository.new(id, name, enabled)
      end
    }

    # TODO FIXME: read other attributes: autorefresh, url, keep_packages, priority

    return repositories
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

    Resolvable.execute('RepoSetData', [@id, 'url', @keep_packages.to_s], 'RepoDetail') { |id, name, enabled|
      Rails.logger.debug "RepoDetail signal received: #{id}, #{name}, #{enabled}"
    }

    # TODO FIXME: libzypp backend cannot change repo url, keep packages flag and name

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
