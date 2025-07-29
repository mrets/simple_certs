require 'ostruct'

class CertificatesController < ApplicationController
  def index
    @certificates = Certificate.all
    render 'index'
  end

  def show
    @certificate = Certificate.find(params[:id])
    render 'show'
  end

  def create
    @certificate = Certificate.new(certificate_params)
    if @certificate.save
      render 'show', status: :created
    else
      @errors = @certificate.errors
      render 'errors'
    end
  end

  def certificate_params
    params.permit(:sn_base, :quantity, :generation_entry_id)
  end
end