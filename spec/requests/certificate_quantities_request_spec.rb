require 'rails_helper'

RSpec.describe 'CertificateQuantities', type: :request do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:account) { create(:account, organization: organization)}
  let(:other_account) { create(:account, organization: other_organization)}
  let(:user) { create(:user, organization: organization) }
  let(:generator) { create(:generator, organization: organization) }
  let(:other_generator) { create(:generator, organization: other_organization) }
  let(:generation) { create(:generation, generator: generator) }
  let(:other_generation) { create(:generation, generator: other_generator) }
  let(:certificate) { create(:certificate, generator: generator, generation: generation) }
  let(:other_certificate) { create(:certificate, generator: other_generator, generation: other_generation) }
  let(:certificate_quantity) { create(:certificate_quantity, certificate: certificate) }
  let(:other_certificate_quantity) { create(:certificate_quantity, certificate: other_certificate) }

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
      'sn_start' => certificate_quantity.sn_start,
      'quantity' => certificate_quantity.quantity,
      'certificate_id' => certificate_quantity.certificate_id,
    }
  end

  context 'index' do
    let!(:certificate_quantity) { create(:certificate_quantity, certificate: certificate, account: account) }
    let!(:other_certificate_quantity) { create(:certificate_quantity, certificate: other_certificate, account: other_account) }

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
      let!(:certificate_quantity) { create(:certificate_quantity, certificate: certificate, account: account) }
      it 'returns a certificate quantity' do
        get "/certificate_quantities/#{certificate_quantity.id}", headers: headers
        json = JSON.parse(response.body)
        expect(json).to eq(certificate_quantity_json(certificate_quantity))
      end
    end

    context "when accessing certificate quantity that is not associated with user's organization" do
      let!(:certificate_quantity) { create(:certificate_quantity, certificate: other_certificate, account: other_account) }
      it 'returns an unauthorized status' do
        get "/certificate_quantities/#{certificate_quantity.id}", headers: headers
        expect(response.code).to eq('401')
      end
    end
  end
end