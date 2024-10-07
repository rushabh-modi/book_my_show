class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include ApplicationHelper
  include Pundit::Authorization
  include Pagy::Backend

  rescue_from ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid, with: :not_found_method
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  # rescue_from NoMethodError, with: :handle_no_method_error

  before_action :configure_permitted_parameters, if: :devise_controller?

  def not_found_method
    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
  end

  http_basic_authenticate_with name: Rails.application.credentials.dig(:superadmin, :username),
                               password: Rails.application.credentials.dig(:superadmin, :password),
                               if: :active_admin_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name status])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name status])
  end

  private

  def active_admin_controller?
    self.class < ActiveAdmin::BaseController
  end

  def user_not_authorized
    flash[:alert] = 'You are not authorized to perform this action.'
    redirect_to root_path
  end

  # TODO: use exception message
  def handle_no_method_error(_exception)
    flash[:alert] = 'Oops! Something went wrong.'
    redirect_back(fallback_location: root_path)
  end

  # devise method for redirecting admin to theater portal after login
  def after_sign_in_path_for(resource)
    if resource&.admin? && resource&.active? && TheaterAdmin.find_by(user: resource)&.active?
      admin_root_path
    elsif resource&.admin? && TheaterAdmin.find_by(user: resource)&.inactive?
      sign_out resource
      flash[:error] = "You can't access the Theater Admin Panel, Contact Support for details"
      root_path
    elsif resource&.inactive?
      sign_out resource
      flash[:error] = "You can't login to application due to some reasons, Contact Support for details"
      root_path
    else
      super
    end
  end
end
