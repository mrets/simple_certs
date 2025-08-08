require "ostruct"

class CertificateQuantitiesController < ApplicationController
  before_action :initialize_logger
  
  def index
    @certificate_quantities = CertificateQuantityPolicy::Scope.new(current_user, CertificateQuantity).resolve
    render "index"
  end

  def show
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    render "show"
  end

  def retire
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    unless @certificate_quantity.status == "active"
      return head :unprocessable_entity
    end

    @certificate_quantity.retire(logger: @transaction_logger)

    render "show"
  rescue CertificateQuantity::InvalidOperationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def transfer
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    account_id = params[:account_id]
    organization_id = params[:organization_id]

    if account_id && organization_id
      return head :unprocessable_entity
    end

    if account_id
      if @certificate_quantity.status != "active"
        return head :unprocessable_entity
      end

      account = Account.find_by(id: account_id)
      if !account || account.organization != current_user.organization
        return head :unprocessable_entity
      end
      
      # Internal transfer within organization
      @certificate_quantity.transfer_internal(account, logger: @transaction_logger)
    elsif organization_id
      organization = Organization.find_by(id: organization_id)
      if !organization || organization == current_user.organization
        return head :unprocessable_entity
      end
      
      # External transfer to different organization
      @certificate_quantity.initiate_transfer(organization, logger: @transaction_logger)
    end

    render "show"
  rescue CertificateQuantity::InvalidOperationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def cancel_transfer
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    unless @certificate_quantity.status == "intransit"
      return head :unprocessable_entity
    end

    @certificate_quantity.cancel_transfer(logger: @transaction_logger)

    render "show"
  rescue CertificateQuantity::InvalidOperationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def accept_transfer
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    unless @certificate_quantity.status == "intransit"
      return head :unprocessable_entity
    end

    @certificate_quantity.accept_transfer(
      current_user.organization.default_account,
      logger: @transaction_logger
    )

    render "show"
  rescue CertificateQuantity::InvalidOperationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def split
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    unless @certificate_quantity.status == "active"
      return head :unprocessable_entity
    end

    quantity = params[:quantity]
    unless /^\d+$/.match(quantity.to_s)
      return head :unprocessable_entity
    end

    quantity = quantity.to_i
    if quantity >= @certificate_quantity.quantity
      return head :unprocessable_entity
    end

    @certificate_quantity.split(quantity, logger: @transaction_logger)

    @certificate_quantity.reload
    render "show"
  rescue ArgumentError, CertificateQuantity::InvalidOperationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
  
  private
  
  def initialize_logger
    @transaction_logger = TransactionLogger.new(
      user: current_user,
      organization: current_user.organization,
      request_id: request.request_id,
      ip_address: request.remote_ip
    )
  end
end