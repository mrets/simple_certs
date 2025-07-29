require 'ostruct'

class CertificateQuantitiesController < ApplicationController
  def index
    @certificate_quantities = CertificateQuantity.all
    render 'index'
  end

  def show
    @certificate_quantity = CertificateQuantity.find(params[:id])
    render 'show'
  end

  def create
    @certificate_quantity = CertificateQuantity.new(certificate_quantity_params)
    if @certificate_quantity.save
      render 'show', status: :created
    else
      @errors = @certificate_quantity.errors
      render 'errors'
    end
  end

  def certificate_quantity_params
    params.permit(:sn_start, :quantity, :certificate_id)
  end
end