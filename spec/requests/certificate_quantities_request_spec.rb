require 'rails_helper'

RSpec.describe 'CertificateQuantities', type: :request do
  let(:json_headers) {
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  }

  def certificate_quantity_json(certificate_quantity)
    {
      'id' => certificate_quantity.id,
      'sn_start' => certificate_quantity.sn_start,
      'quantity' => certificate_quantity.quantity,
      'certificate_id' => certificate_quantity.certificate_id,
    }
  end

  context 'index' do
    let!(:certificate_quantity) { create(:certificate_quantity) }
    it 'returns certificate quantities' do
      get '/certificate_quantities', headers: json_headers
      json = JSON.parse(response.body)
      expect(json).to eq(
        {
          'certificate_quantities' => [ certificate_quantity_json(certificate_quantity) ]
        }
      )
    end
  end

  context 'show' do
    let!(:certificate_quantity) { create(:certificate_quantity) }
    it 'returns a certificate quantity' do
      get "/certificate_quantities/#{certificate_quantity.id}", headers: json_headers
      json = JSON.parse(response.body)
      expect(json).to eq(certificate_quantity_json(certificate_quantity))
    end
  end

  context 'create' do
    let(:certificate) { create(:certificate) }
    let(:body) {
      {
        'sn_start' => 1000,
        'quantity' => 50,
        'certificate_id' => certificate.id
      }
    }

    before do
      post '/certificate_quantities', headers: json_headers, params: body.to_json
    end

    it 'creates a certificate quantity' do
      expect(CertificateQuantity.count).to eq(1)
    end

    it 'has the correct status' do
      expect(response.status).to eq(201)
    end

    it 'creates the certificate quantity with the correct data' do
      json = JSON.parse(response.body)
      certificate_quantity = CertificateQuantity.find(json['id'])
      attrs = certificate_quantity.attributes.slice(*%w(sn_start quantity certificate_id))
      expect(attrs).to eq(body)
    end

    it 'returns the body with the correct body' do
      json = JSON.parse(response.body)
      certificate_quantity = CertificateQuantity.find(json['id'])
      expect(json).to eq(certificate_quantity_json(certificate_quantity))
    end
  end
end 