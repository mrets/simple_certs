require "ostruct"

class CertificateQuantitiesController < ApplicationController
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

    TransactionJob.perform_later(@transaction, id: params[:id])
    render "show", status: :accepted
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
    end

    if organization_id
      organization = Organization.find_by(id: organization_id)
      if !organization || organization == current_user.organization
        return head :unprocessable_entity
      end
    end

    if account_id
      TransactionJob.perform_later(@transaction, {id: params[:id], account_id: account_id})
    elsif organization_id
      TransactionJob.perform_later(@transaction, {id: params[:id], organization_id: organization_id})
    end

    render "show"
  end

  def cancel_transfer
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    unless @certificate_quantity.status == "intransit"
      return head :unprocessable_entity
    end

    TransactionJob.perform_later(@transaction, id: params[:id])

    render "show"
  end

  def accept_transfer
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    unless @certificate_quantity.status == "intransit"
      return head :unprocessable_entity
    end

    TransactionJob.perform_later(@transaction, {id: params[:id], account: current_user.organization.default_account_id})

    render "show"
  end

  def split
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    # Future improvement: These validations should happen before the job.
    # That would allow them to validate based on the current state, not the prior one.
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

    TransactionJob.perform_later(@transaction, {id: params[:id], quantity: params[:quantity].to_i})
    
    render "show"
  end
end
