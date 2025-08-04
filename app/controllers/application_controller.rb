class ApplicationController < ActionController::API
  include Pundit::Authorization
  before_action :verify_user

  attr_reader :current_user
  rescue_from Pundit::NotAuthorizedError, with: :unauthorized

  def verify_user
    @current_user = User.find_by(api_key: request.headers["X-Api-Key"])
    return if @current_user

    unauthorized
  end

  private

  def unauthorized
    head :unauthorized
  end
end
