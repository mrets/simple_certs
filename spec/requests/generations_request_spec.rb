require 'rails_helper'

RSpec.describe 'Generations', type: :request do
  let!(:generation) { create(:generation) }
  let(:json_headers) {
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  }

  context 'index' do
    it 'returns generations' do
      get '/generations', headers: json_headers
      json = JSON.parse(response.body)
      expect(json).to eq(
        {
          'generations' => [
            {
              'id' => generation.id,
              'start_date' => generation.start_date&.iso8601,
              'end_date' => generation.end_date&.iso8601,
              'quantity' => generation.quantity,
              'generator_id' => generation.generator_id,
            }
          ]
        }
      )
    end
  end

  context 'show' do
    it 'returns a generation' do
      get "/generations/#{generation.id}", headers: json_headers
      json = JSON.parse(response.body)
      expect(json).to eq(
        {
          'id' => generation.id,
          'start_date' => generation.start_date&.iso8601,
          'end_date' => generation.end_date&.iso8601,
          'quantity' => generation.quantity,
          'generator_id' => generation.generator_id,
        }
      )
    end
  end

  context 'create' do
    let(:body) {
      {
        start_date: Date.new(2025, 2, 1),
        end_date: Date.new(2025, 2, 28),
        quantity: 80
      }
    }

    it 'creates a generation' do
      post '/generations', headers: json_headers, params: body.to_json
      expect(response.status).to eq(201)
      expect(Generation.count).to eq(2)
    end
  end
end
