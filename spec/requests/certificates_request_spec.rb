require 'rails_helper'

RSpec.describe 'Certificates', type: :request do
  let(:json_headers) {
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  }

  def certificate_json(certificate)
    {
      'id' => certificate.id,
      'sn_base' => certificate.sn_base,
      'quantity' => certificate.quantity,
      'generation_entry_id' => certificate.generation_entry_id,
    }
  end

  context 'index' do
    let!(:certificate) { create(:certificate) }
    it 'returns certificates' do
      get '/certificates', headers: json_headers
      json = JSON.parse(response.body)
      expect(json).to eq(
        {
          'certificates' => [ certificate_json(certificate) ]
        }
      )
    end
  end

  context 'show' do
    let!(:certificate) { create(:certificate) }
    it 'returns a certificate' do
      get "/certificates/#{certificate.id}", headers: json_headers
      json = JSON.parse(response.body)
      expect(json).to eq(certificate_json(certificate))
    end
  end

  context 'create' do
    let(:body) {
      {
        'sn_base' => 'CERT001',
        'quantity' => 100,
        'generation_entry_id' => 1
      }
    }

    before do
      post '/certificates', headers: json_headers, params: body.to_json
    end

    it 'creates a certificate' do
      expect(Certificate.count).to eq(1)
    end

    it 'has the correct status' do
      expect(response.status).to eq(201)
    end

    it 'creates the certificate with the correct data' do
      json = JSON.parse(response.body)
      certificate = Certificate.find(json['id'])
      attrs = certificate.attributes.slice(*%w(sn_base quantity generation_entry_id))
      expect(attrs).to eq(body)
    end

    it 'returns the body with the correct body' do
      json = JSON.parse(response.body)
      certificate = Certificate.find(json['id'])
      expect(json).to eq(certificate_json(certificate))
    end
  end
end 