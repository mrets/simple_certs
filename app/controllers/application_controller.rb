class ApplicationController < ActionController::API
  include Pundit::Authorization
  before_action :verify_user
  before_action :draft_transaction

  attr_reader :current_user
  rescue_from Pundit::NotAuthorizedError, with: :unauthorized

  def verify_user
    @current_user = User.find_by(api_key: request.headers["X-Api-Key"])
    return if @current_user

    unauthorized
  end

  def draft_transaction
    # This is added to the application controller to ensure consistency if it gets applied to other resources.
    # However, since the exercise deals with the Certificate Quantities, it only looks at this table.
    if controller_name == 'certificate_quantities'
      unless ['index', 'show'].include? action_name
        @transaction = {
          request_uuid: request.request_id,
          request_user_id: @current_user.id,
          initiated_at: Time.now,
          resource: controller_name,
          action: action_name
        }
      end
    end
  end

  private

  def unauthorized
    head :unauthorized
  end
end
