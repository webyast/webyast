#--
# Webyast framework
#
# Copyright (C) 2009, 2010 Novell, Inc.
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation.
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++
class SessionsController < Devise::SessionsController
  include FastGettext::Translation

  def initialize
    I18n.locale = FastGettext.locale
    super
  end

  def create
    if (params[:remember_me] == "true" || params[:login].try(:[], :remember_me)) && current_account.present? && current_account.authentication_token.blank?
      Rails.logger.info "Creating authentication token for user #{current_account.username}"

      PluginJob.try_updating_db do
        current_account.reset_authentication_token!
      end
    end

    super
  end

  def destroy
    if (params[:forget_me] == "true" || params[:login].try(:[], :forget_me)) && current_account.present? && current_account.authentication_token.present?
      Rails.logger.info "Resetting authentication token for user #{current_account.username}"
      current_account.authentication_token = nil

      PluginJob.try_updating_db do
        current_account.save!
      end
    end

    super
  end
end
