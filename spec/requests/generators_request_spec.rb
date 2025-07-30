require 'rails_helper'

RSpec.describe 'Generators', type: :request do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:generator) { create(:generator, organization: organization) }
  let(:other_generator) { create(:generator, organization: other_organization) }

  let(:json_headers) {
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  }
  let(:user_header) {
    { 'X-Api-Key' => user.api_key }
  }
  let(:headers) {
    json_headers.merge(user_header)
  }

  def generator_json(generator)
    {
      'id' => generator.id,
      'name' => generator.name,
      'ext_id' => generator.ext_id,
      'organization_id' => generator.organization_id
    }
  end

  context 'index' do
    let!(:generator) { create(:generator, organization: organization) }
    let!(:other_generator) { create(:generator, organization: other_organization) }

    before do
      get '/generators', headers: headers
    end

    it 'has a 200 status' do
      expect(response.status).to eq(200)
    end

    it 'returns generators' do
      json = JSON.parse(response.body)
      expect(json).to eq(
        {
          'generators' => [ generator_json(generator) ]
        }
      )
    end
  end

  context 'show' do
    context "when accessing generator that is associated with user's organization" do
      let!(:generator) { create(:generator, organization: organization) }
      it 'returns a generator' do
        get "/generators/#{generator.id}", headers: headers
        json = JSON.parse(response.body)
        expect(json).to eq(generator_json(generator))
      end
    end

    context "when accessing generator that is not associated with user's organization" do
      let!(:generator) { create(:generator, organization: other_organization) }
      it 'returns an unauthorized status' do
        get "/generators/#{generator.id}", headers: headers
        expect(response.code).to eq('401')
      end
    end
  end

  context 'create' do
    let(:body) {
      {
        'name' => 'Test Generator',
        'ext_id' => 'GEN001',
        'organization_id' => organization.id
      }
    }

    before do
      post '/generators', headers: headers, params: body.to_json
    end

    context "when creating generator that is associated with the user's organization" do
      it 'creates a generator' do
        expect(Generator.count).to eq(1)
      end

      it 'has the correct status' do
        expect(response.status).to eq(201)
      end

      it 'creates the generator with the correct data' do
        json = JSON.parse(response.body)
        generator = Generator.find(json['id'])
        attrs = generator.attributes.slice(*%w(name ext_id organization_id))
        expect(attrs).to eq(body)
      end

      it 'returns the body with the correct body' do
        json = JSON.parse(response.body)
        generator = Generator.find(json['id'])
        expect(json).to eq(generator_json(generator))
      end
    end

    context "when creating generator that is NOT associated with the user's organization" do
      let(:body) {
        {
          'name' => 'Test Generator',
          'ext_id' => 'GEN001',
          'organization_id' => other_organization.id
        }
      }

      it 'returns an unauthorized status' do
        expect(response.code).to eq('401')
      end
    end
  end
end 