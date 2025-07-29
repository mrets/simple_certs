require 'rails_helper'

RSpec.describe 'Generations', type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:generator) { create(:generator, organization: organization) }

  let(:json_headers) {
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  }
  let(:user_header) {
    { 'X-Api-Key' => user.api_key }
  }
  let(:headers) {
    json_headers.merge(user_header)
  }

  def generation_json(generation)
    {
      'id' => generation.id,
      'start_date' => generation.start_date&.iso8601,
      'end_date' => generation.end_date&.iso8601,
      'quantity' => generation.quantity,
      'generator_id' => generation.generator_id,
    }
  end

  context 'index' do
    let!(:generation) { create(:generation, generator: generator) }

    before do
      get '/generations', headers: headers
    end

    it 'has a 200 status' do
      expect(response.status).to eq(200)
    end

    it 'returns generations' do
      json = JSON.parse(response.body)
      expect(json).to eq(
        {
          'generations' => [ generation_json(generation) ]
        }
      )
    end
  end

  context 'show' do
    let!(:generation) { create(:generation, generator: generator) }
    it 'returns a generation' do
      get "/generations/#{generation.id}", headers: headers
      json = JSON.parse(response.body)
      expect(json).to eq(generation_json(generation))
    end
  end

  context 'create' do
    let(:body) {
      {
        'start_date'  => Date.new(2025, 2, 1),
        'end_date' => Date.new(2025, 2, 28),
        'quantity' => 80,
        'generator_id' => generator.id
      }
    }

    before do
      post '/generations', headers: headers, params: body.to_json
    end

    it 'creates a generation' do
      expect(Generation.count).to eq(1)
    end

    it 'has the correct status' do
      expect(response.status).to eq(201)
    end

    it 'creates the generation with the correct data' do
      json = JSON.parse(response.body)
      generation = Generation.find(json['id'])
      attrs = generation.attributes.slice(*%w(start_date end_date quantity generator_id))
      expect(attrs).to eq(body)
    end

    it 'returns the body with the correct body' do
      json = JSON.parse(response.body)
      generation = Generation.find(json['id'])
      expect(json).to eq(generation_json(generation))
    end
  end
end
