class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include ApplicationHelper

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :store_user_location!, if: :storable_location?

  http_basic_authenticate_with name: Rails.application.credentials.dig(:superadmin, :username),
                               password: Rails.application.credentials.dig(:superadmin, :password),
                               if: :active_admin_controller?

  def active_admin_controller?
    self.class < ActiveAdmin::BaseController
  end

  protected

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr? 
  end

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end

  # devise method for redirecting admin to theater portal after login
  def after_sign_in_path_for(resource_or_scope)
    if resource.admin?
      admin_root_path
    else
      stored_location_for(resource_or_scope) || root_path
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end
