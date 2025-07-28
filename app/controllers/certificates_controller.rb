class CertificatesController < ApplicationController
  def index
    @certificates = Certificate.all
  end
end