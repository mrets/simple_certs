require 'rails_helper'

RSpec.describe 'Generators', type: :request do
  let(:json_headers) {
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  }

  def generator_json(generator)
    {
      'id' => generator.id,
      'name' => generator.name,
      'ext_id' => generator.ext_id,
    }
  end

  context 'index' do
    let!(:generator) { create(:generator) }
    it 'returns generators' do
      get '/generators', headers: json_headers
      json = JSON.parse(response.body)
      expect(json).to eq(
        {
          'generators' => [ generator_json(generator) ]
        }
      )
    end
  end

  context 'show' do
    let!(:generator) { create(:generator) }
    it 'returns a generator' do
      get "/generators/#{generator.id}", headers: json_headers
      json = JSON.parse(response.body)
      expect(json).to eq(generator_json(generator))
    end
  end

  context 'create' do
    let(:body) {
      {
        'name' => 'Test Generator',
        'ext_id' => 'GEN001'
      }
    }

    before do
      post '/generators', headers: json_headers, params: body.to_json
    end

    it 'creates a generator' do
      expect(Generator.count).to eq(1)
    end

    it 'has the correct status' do
      expect(response.status).to eq(201)
    end

    it 'creates the generator with the correct data' do
      json = JSON.parse(response.body)
      generator = Generator.find(json['id'])
      attrs = generator.attributes.slice(*%w(name ext_id))
      expect(attrs).to eq(body)
    end

    it 'returns the body with the correct body' do
      json = JSON.parse(response.body)
      generator = Generator.find(json['id'])
      expect(json).to eq(generator_json(generator))
    end
  end
end 