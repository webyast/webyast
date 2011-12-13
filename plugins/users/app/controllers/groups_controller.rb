#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

include ApplicationHelper

class GroupsController < ApplicationController
  
  layout 'main'

  # Initialize GetText and Content-Type.
  FastGettext.add_text_domain 'webyast-users', :path => 'locale'

private

  def validate_group_id( id = params[:id] )
    if id.blank?
      respond_to do |format|
        format.html { flash[:error] = _('Missing group name parameter')
                      redirect_to :action => :index }
        format.xml  { render ErrorResult.error(404, 2, 'Missing group name parameter') }
        format.json { render ErrorResult.error(404, 2, 'Missing group name parameter') }
      end
      false
    else
      true
    end
  end

  def validate_group_params( redirect_action )
    if params[:group] && (! params[:group].empty?)
      true
    else
      respond_to do |format|
        format.html { flash[:error] = _('Missing group parameters')
                      redirect_to :action => :index }
        format.xml  { render ErrorResult.error(404, 2, 'Missing group parameters') }
        format.json { render ErrorResult.error(404, 2, 'Missing group parameters') }
      end
      false
    end
  end

  def validate_group_name( redirect_action )
    if params[:group] && params[:group][:cn] =~ /[a-z]+/
      true
    else
      respond_to do |format|
        format.html { flash[:error] = _('Please enter a valid group name')
                      redirect_to :action => :index }
        format.xml  { render ErrorResult.error(404, 2, 'Please enter a valid group name') }
        format.json { render ErrorResult.error(404, 2, 'Please enter a valid group name') }
      end
      false
    end
  end

  def validate_group_gid( redirect_action )
    if params[:group] && params[:group][:gid] =~ /\d+/
      true
    else
      respond_to do |format|
        format.html { flash[:error] = _('Please enter a valid GID')
                      redirect_to :action => :index }
        format.xml  { render ErrorResult.error(404, 2, 'Please enter a valid GID') }
        format.json { render ErrorResult.error(404, 2, 'Please enter a valid GID') }
      end
      false
    end
  end

  def validate_group_type( redirect_action )
    if params[:group] && ["system","local"].include?( params[:group][:group_type] )
      true
    else
      respond_to do |format|
        format.html { flash[:error] = _('Please enter a valid group type. Only "system" or "local" are allowed.')
                      redirect_to :action => :index }
        format.xml  { render ErrorResult.error(404, 2, 'Please enter a valid group type. Only "system" or "local" are allowed.') }
        format.json { render ErrorResult.error(404, 2, 'Please enter a valid group type. Only "system" or "local" are allowed.') }
      end
      false
    end
  end

  def validate_members( redirect_action )
    member = "[a-z]+"
    if params[:group] && params[:group][:members_string] =~ /(#{member}( *, *#{member})+)?/
      true
    else
      respond_to do |format|
        format.html { flash[:error] = _('Please enter a valid list of members')
                      redirect_to :action => :index }
        format.xml  { render ErrorResult.error(404, 2, 'Please enter a valid list of members') }
        format.json { render ErrorResult.error(404, 2, 'Please enter a valid list of members') }
      end
      false
    end
  end


  # log Group.find error and provide matching ErrorResult
  def group_not_found gid
    Rails.logger.error "Group #{gid} was not found."
    ErrorResult.error(404, 2, "group #{gid} not found")
  end
  
public

  # GET /groups/users
  # GET /groups/users.xml
  def show
    authorize! :get, Group
    # try to find the grouplist, and 404 if it does not exist
    @group = Group.find params[:id]
    if @group.nil?
      render group_not_found(params[:id]) and return
    end

    respond_to do |format|
      format.xml { render  :xml => @group.to_xml( :dasherize => false ) }
      format.json { render :json => @group.to_json }
    end
  end

  # GET /groups.xml
  def index
    authorize! :get, Group
    @groups = Group.find_all
    Rails.logger.error "No groups found." unless @groups
    respond_to do |format|
      format.xml { 
        if @groups.nil?
          render ErrorResult.error(404, 2, "No groups found")
        else
          render  :xml => @groups.to_xml(:root => "groups", 
                  :dasherize => false ) 
        end
        return
      }
      format.json {
        if @groups.nil?
          render ErrorResult.error(404, 2, "No groups found")
        else
          render :json => @groups.to_json 
        end
        return
      }
      format.html { 
        @groups.sort! { |a,b| a.cn <=> b.cn } if @groups
        @all_users_string = ""
        @all_sys_users_string = ""
        @users = []
        @sys_users = []
        @users     = User.find_all({ :attributes => "uid"})
        @sys_users = User.find_all({ "attributes"=>"cn,uidNumber,uid", 
                                     "type"=>"system", 
                                     "index"=>["s", "uid"]} )
        @users.each do |user|
          if @all_users_string.blank?
            @all_users_string = user.uid
          else
            @all_users_string += ",#{user.uid}"
          end
        end

        @sys_users.each do |user|
          if @all_sys_users_string.blank?
            @all_sys_users_string = user.uid
          else
            @all_sys_users_string += ",#{user.uid}"
          end
        end
        render :index
      }
    end
  end

  def new
    authorize! :add, Group
    @group = Group.new

    # add default properties
    defaults = {
      :gid => 0,
      :old_cn => "",
      :members => [],
      :group_type => "local",
      :cn => "",
    }
    @group.load(defaults)
    @adding = true
    @all_users_string = ""
    users = User.find(:all) if can? :get, User
    users.each do |user|
      if @all_users_string.blank?
        @all_users_string = user.uid
      else
        @all_users_string += ",#{user.uid}"
      end
    end
    render :new
  end

  # POST /groups/users/
  def update
    validate_group_id(params[:group][:old_cn]) or return
    validate_group_params( :index ) or return
    validate_group_name( :index ) or return
    validate_members( :index ) or return
    group_params = params[:group] || {}
    @group = Group.new group_params
    @group.members = group_params[:members_string].split(",").collect {|cn| cn.strip} unless group_params[:members_string].blank?
    result = @group.save
    Rails.logger.error "Cannot update group '#{@group.cn}' (#{@group.inspect}): #{result}" unless result.blank?
    respond_to do |format|
      format.html { unless result.blank?
                      flash[:error] = _("Cannot update group <i>%s</i>") % @group.cn
                      render :edit
                    else
                      flash[:message] = _("Group <i>%s</i> has been updated.") % @group.cn 
                      redirect_to :action => :index 
                    end
                  }
      format.xml  { unless result.blank?
                      render ErrorResult.error(404, 2, "Group update error:'"+result+"'")
                    else
                      render :show
                    end
                  }
      format.json { unless result.blank?
                      render ErrorResult.error(404, 2, "Group update error:'"+result+"'")
                    else
                      render :show
                    end
                  }
    end
  end

  # PUT /groups/
  def create
    authorize :add, Group
    validate_group_params( :new ) or return
    validate_group_name( :new ) or return
    group_params = params[:group] || {}
    group_params[:old_cn] = group_params[:cn]
    validate_members( :new ) or return
    validate_group_type( :new ) or return
    @group = Group.new group_params
    @group.members = group_params[:members_string].split(",").collect {|cn| cn.strip} unless group_params[:members_string].blank?
    result = @group.save
    Rails.logger.error "Cannot create group '#{@group.cn}': #{result}" unless result.blank?
    respond_to do |format|
      format.html { unless result.blank?
                      flash[:error] = _("Cannot create group <i>%s</i>") % @group.cn
                      redirect_to :action => :new
                    else
                      flash[:message] = _("Group <i>%s</i> has been added.") % @group.cn 
                      redirect_to :action => :index 
                    end
                  }
      format.xml  { unless result.blank?
                      render ErrorResult.error(404, 2, "Group create error:'"+result+"'")
                    else
                      render :show
                    end
                  }
      format.json { unless result.blank?
                      render ErrorResult.error(404, 2, "Group create error:'"+result+"'")
                    else
                      render :show
                    end
                  }
    end
  end

  # DELETE /groups/users
  def destroy
    authorize! :delete, Group
    validate_group_id or return

    @group = Group.find(params[:id])

    if @group.nil?
      result = "group #{params[:id]} not found" 
    else
      result = @group.destroy
    end

    Rails.logger.error "Cannot destroy group '#{@group.cn}': #{result}" unless result.blank?
    respond_to do |format|
      format.html { unless result.blank?
                      flash[:error] = _("Cannot remove group <i>%{name}</i>: %{result}") % {:name => @group.cn, :result => result}
                    else
                      flash[:message] = _("Group <i>%s</i> has been deleted.") % @group.cn 
                    end
                    redirect_to :action => :index 
                  }
      format.xml  { unless result.blank?
                      render ErrorResult.error(404, 2, "Group destroy error:'"+result+"'")
                    else
                      render :show
                    end
                  }
      format.json { unless result.blank?
                      render ErrorResult.error(404, 2, "Group destroy error:'"+result+"'")
                    else
                      render :show
                    end
                  }
    end
  end
end
