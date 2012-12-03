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
  include ERB::Util

  def show
    authorize! :groupget, User
    # try to find the grouplist, and 404 if it does not exist
    # RORSCAN_INL: User has already read permission for ALL groups here
    group_name = params[:id]
    @group = Group.find group_name
    if @group
      respond_to do |format|
        format.xml  { render  :xml => @group.to_xml(:dasherize => false) }
        format.json { render :json => @group.to_json }
      end
    else
      Rails.logger.error "Group '#{group_name}' not found" unless @groups
      render ErrorResult.error(404, 2, "Group with name '#{group_name}' not found")
    end
  end

  def index
    authorize! :groupsget, User
    @groups = Group.find_all
    if @groups
      respond_to do |format|
        format.html do
          @groups.sort! { |a,b| a.cn <=> b.cn }
          @users = []
          @sys_users = []
          @users     = User.find_all({ :attributes => "uid"})
          @sys_users = User.find_all({ "attributes"=>"cn,uidNumber,uid",
           "type"=>"system", "index"=>["s", "uid"]} )
          @all_users_string = @users.map(&:uid).join(',')
          @all_sys_users_string = @sys_users.map(&:uid).join(',')
          render :index
        end
        format.xml do
          render :xml=>@groups.to_xml(:root=>"groups", :dasherize=>false )
        end
        format.json do
          render :json=>@groups.to_json(:root=>"groups")
        end
      end
    else
      Rails.logger.error "No groups found."
      error = ErrorResult.error 404, 2, "No groups found"
      respond_to do |format|
        format.html { render error }
        format.xml  { render :xml=>error  }
        format.json { render :json=>error }
      end
    end
  end

  def new
    authorize! :groupadd, User
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
    users = User.find(:all) if can? :usersget, User
    users.each do |user|
      if @all_users_string.blank?
        @all_users_string = user.uid
      else
        @all_users_string += ",#{user.uid}"
      end
    end
    render :new
  end

  def update
    group_params = params[:group] || {}
    @group = Group.new group_params
    @group.members = group_params[:members_string].split(",").collect {|cn| cn.strip} unless group_params[:members_string].blank?
    if @group.valid?
      result = @group.save
      if result.present?
        flash[:message] = (_("Group <i>%s</i> has been updated.") % h(@group.cn)).html_safe
        respond_to do |format|
          format.html { redirect_to :action => :index }
          format.xml  { render :show }
          format.json { render :show }
        end
      else
        Rails.logger.error "Cannot update group '#{@group.cn}' (#{@group.inspect}): #{result}"
        respond_to do |format|
          format.html do
            flash[:error] = (_("Cannot update group <i>%s</i>, %s") % [h(@group.cn), result]).html_safe
            redirect_to :action => :index
          end
          format.xml  { render ErrorResult.error(404, 2, "Group update error:'#{result}'") }
          format.json { render ErrorResult.error(404, 2, "Group update error:'#{result}'") }
        end
      end
    else
      flash[:error] = @group.errors.full_messages
      redirect_to :action=>:index
    end
  end

  # PUT /groups/
  def create
    authorize! :groupadd, User
   #validate_group_params( :new ) or return
   #validate_group_name( :new ) or return
    group_params = params[:group] || {}
    group_params[:old_cn] = group_params[:cn]
   #validate_members( :new ) or return
   #validate_group_type( :new ) or return
    @group = Group.new group_params
    @group.members = group_params[:members_string].split(",").collect {|cn| cn.strip} unless group_params[:members_string].blank?
    result = @group.save
    Rails.logger.error "Cannot create group '#{@group.cn}': #{result}" unless result.blank?
    respond_to do |format|
      format.html { unless result.blank?
                      flash[:error] = (_("Cannot create group <i>%s</i>") % h(@group.cn)).html_safe
                      redirect_to :action => :new
                    else
                      flash[:message] = (_("Group <i>%s</i> has been added.") % h(@group.cn)).html_safe
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
    authorize! :groupdelete, User
    validate_group_id or return
    cn = params[:id]
    # RORSCAN_INL: User has already delete permission for ALL groups here
    @group = Group.find(cn)

    if @group.nil?
      result = "group #{cn} not found"
    else
      result = @group.destroy
    end

    Rails.logger.error "Cannot destroy group '#{cn}': #{result}" if result.present?
    respond_to do |format|
      format.html { if result.present?
                      flash[:error] = (_("Cannot remove group <i>%{name}</i>: %{result}").to_str % {:name => h(cn), :result => h(result)}).html_safe
                    else
                      flash[:message] = (_("Group <i>%s</i> has been deleted.") % h(cn) ).html_safe
                    end
                    redirect_to :action => :index
                  }
      format.xml  { if result.present?
                      render ErrorResult.error(404, 2, "Group destroy error:'"+result+"'")
                    else
                      render :show
                    end
                  }
      format.json { if result.present?
                      render ErrorResult.error(404, 2, "Group destroy error:'"+result+"'")
                    else
                      render :show
                    end
                  }
    end
  end
end
