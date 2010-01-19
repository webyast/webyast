# class Repository represents a software repository

require 'resolvable'

# TODO FIXME: repository is NOT a resolvable, unfortunately we need to
# call private method execute() somehow, it should be probably factored
# out to a separate class/module
class Repository < Resolvable

  attr_accessor   :repo_alias,
    :name,
    :enabled,
    :autorefresh,
    :url,
    :priority,
    :keep_packages

  def initialize(repo_alias, name, enabled)
    @repo_alias = repo_alias
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

    Resolvable.execute('GetRepoList', 'NONE', 'RepoDetail') { |repo_alias, name, enabled|
      Rails.logger.debug "RepoDetail signal received: #{repo_alias}, #{name}, #{enabled}"

      if what == :all || repo_alias == what
        repositories << Repository.new(repo_alias, name, enabled)
      end
    }

    return repositories
  end

  def self.exists?(repo_alias)
    self.find(:all).any? {|repo|
      repo.repo_alias == repo_alias
    }
  end

  def save
    return false if @repo_alias.blank?

    # create a new repository if it does not exist yet
    if !Repository.exists?(@repo_alias)
      Resolvable.execute('RepoSetData', [@repo_alias, 'add', @url], 'RepoDetail') { |repo_alias, name, enabled|
        Rails.logger.debug "RepoDetail signal received: #{repo_alias}, #{name}, #{enabled}"
      }
    end

    # TODO: save repository properties here...
    Resolvable.execute('RepoEnable', [@repo_alias, @enabled], 'RepoDetail') { |repo_alias, name, enabled|
      Rails.logger.debug "RepoDetail signal received: #{repo_alias}, #{name}, #{enabled}"
    }

    # set priority
    Resolvable.execute('RepoSetData', [@repo_alias, 'prio', @priority], 'RepoDetail') { |repo_alias, name, enabled|
      Rails.logger.debug "RepoDetail signal received: #{repo_alias}, #{name}, #{enabled}"
    }

    # set autorefresh
    Resolvable.execute('RepoSetData', [@repo_alias, 'refresh', @autorefresh], 'RepoDetail') { |repo_alias, name, enabled|
      Rails.logger.debug "RepoDetail signal received: #{repo_alias}, #{name}, #{enabled}"
    }

    # TODO FIXME: libzypp backend cannot change repo url, keep packages flag, name

    return true
  end

  def destroy
    return false if @repo_alias.blank?

    Resolvable.execute('RepoSetData', [@repo_alias, 'remove', 'NONE'], 'RepoDetail') { |repo_alias, name, enabled|
      Rails.logger.debug "RepoDetail signal received: #{repo_alias}, #{name}, #{enabled}"
    }
    
    return true
  end

  def to_xml(options = {})
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.tag! :repository do
      xml.tag!(:repo_alias, @repo_alias)
      xml.tag!(:name, @name)
      xml.tag!(:url, @url)
      xml.tag!(:enabled, @enabled, {:type => "boolean"})
      xml.tag!(:autorefresh, @autorefresh, {:type => "boolean"})
      xml.tag!(:keep_packages, @keep_packages, {:type => "boolean"})
      xml.tag!(:priority, @priority, {:type => "integer"})
    end
  end

end
