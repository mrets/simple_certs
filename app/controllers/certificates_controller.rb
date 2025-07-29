require 'ostruct'

class CertificatesController < ApplicationController
  def index
    @certificates = CertificatePolicy::Scope.new(current_user, Certificate).resolve
    render 'index'
  end

  def show
    @certificate = Certificate.find(params[:id])
    authorize @certificate

    render 'show'
  end

  def create
    @certificate = Certificate.new(certificate_params)
    authorize @certificate

    if @certificate.save
      render 'show', status: :created
    else
      @errors = @certificate.errors
      render 'errors'
    end
  end

  def certificate_params
    params.permit(:sn_base, :quantity, :generator_id)
  end
end