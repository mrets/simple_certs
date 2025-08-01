require 'ostruct'

class CertificateQuantitiesController < ApplicationController
  def index
    @certificate_quantities = CertificateQuantityPolicy::Scope.new(current_user, CertificateQuantity).resolve
    render 'index'
  end

  def show
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    render 'show'
  end

  def retire
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    @certificate_quantity.update(status: 'retired')

    render 'show'
  end

  def transfer
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    account_id = params[:account_id]
    organization_id = params[:organization_id]
    if account_id
      account = Account.find(account_id)
      @certificate_quantity.update(account: account)
    elsif organization_id
      organization = Organization.find(organization_id)
      @certificate_quantity.update(status: 'intransit', to_organization: organization)
    end

    render 'show'
  end

  def cancel_transfer
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    @certificate_quantity.update(status: 'active', to_organization: nil)

    render 'show'
  end

  def accept_transfer
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    @certificate_quantity.update(status: 'active', to_organization: nil, account: current_user.organization.default_account)

    render 'show'
  end

  def split
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    @certificate_quantity.split(params[:quantity].to_i)

    @certificate_quantity.reload
    render 'show'
  end
end