class CertificateQuantiesController < ApplicationController
  def index
    @certifcate_quantities = CertificateQuantity.all
  end
end