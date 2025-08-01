require 'rails_helper'

RSpec.describe 'CertificateQuantities', type: :request do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:account) { create(:account, organization: organization)}
  let(:other_account) { create(:account, organization: other_organization)}
  let(:user) { create(:user, organization: organization) }
  let(:generator) { create(:generator, organization: organization) }
  let(:other_generator) { create(:generator, organization: other_organization) }
  let!(:generation) { create(:generation, generator: generator) }
  let!(:other_generation) { create(:generation, generator: other_generator) }
  let(:certificate) { generation.certificate }
  let(:other_certificate) { other_generation.certificate }
  let(:certificate_quantity) { certificate.reload.certificate_quantities.first }
  let(:other_certificate_quantity) { other_certificate.reload.certificate_quantities.first }

  let(:json_headers) {
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  }
  let(:user_header) {
    { 'X-Api-Key' => user.api_key }
  }
  let(:headers) {
    json_headers.merge(user_header)
  }

  def certificate_quantity_json(certificate_quantity)
    {
      'id' => certificate_quantity.id,
      'quantity' => certificate_quantity.quantity,
      'certificate_id' => certificate_quantity.certificate_id,
      'status' => certificate_quantity.status
    }
  end

  context 'index' do
    before do
      get '/certificate_quantities', headers: headers
    end

    it 'has a 200 status' do
      expect(response.status).to eq(200)
    end

    it 'returns certificate quantities' do
      json = JSON.parse(response.body)
      expect(json).to eq(
        {
          'certificate_quantities' => [ certificate_quantity_json(certificate_quantity) ]
        }
      )
    end
  end

  context 'show' do
    context "when accessing certificate quantity that is associated with user's organization" do
      it 'returns a certificate quantity' do
        get "/certificate_quantities/#{certificate_quantity.id}", headers: headers
        json = JSON.parse(response.body)
        expect(json).to eq(certificate_quantity_json(certificate_quantity))
      end
    end

    context "when accessing certificate quantity that is not associated with user's organization" do
      it 'returns an unauthorized status' do
        get "/certificate_quantities/#{other_certificate_quantity.id}", headers: headers
        expect(response.code).to eq('401')
      end
    end
  end

  context 'retire' do
    context "when retiring a certificate that is associated with the user's organization" do
      before do
        put "/certificate_quantities/#{certificate_quantity.id}/retire", headers: headers
      end

      it 'returns a 200 status' do
        expect(response.code).to eq('200')
      end

      it 'responds with the updated certificate status' do
        json = JSON.parse(response.body)
        expect(json).to eq(certificate_quantity_json(certificate_quantity.reload))
      end

      it 'modifies the certificate status to retired' do
        expect(certificate_quantity.reload.status).to eq('retired')
      end
    end

    context "when retiring a certificate that is not associated with the user's organization" do
      it 'returns an unauthorized status' do
        put "/certificate_quantities/#{other_certificate_quantity.id}/retire", headers: headers
        expect(response.code).to eq('401')
      end
    end
  end
end