require 'rails_helper'

RSpec.describe 'Accounts', type: :request do
  let(:json_headers) {
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  }

  def account_json(account)
    {
      'id' => account.id,
      'name' => account.name,
      'organization_id' => account.organization_id,
    }
  end

  context 'index' do
    let!(:account) { create(:account) }
    it 'returns accounts' do
      get '/accounts', headers: json_headers
      json = JSON.parse(response.body)
      expect(json).to eq(
        {
          'accounts' => [ account_json(account) ]
        }
      )
    end
  end

  context 'show' do
    let!(:account) { create(:account) }
    it 'returns an account' do
      get "/accounts/#{account.id}", headers: json_headers
      json = JSON.parse(response.body)
      expect(json).to eq(account_json(account))
    end
  end

  context 'create' do
    let(:organization) { create(:organization) }
    let(:body) {
      {
        'name' => 'Test Account',
        'organization_id' => organization.id
      }
    }

    before do
      post '/accounts', headers: json_headers, params: body.to_json
    end

    it 'creates an account' do
      expect(Account.count).to eq(1)
    end

    it 'has the correct status' do
      expect(response.status).to eq(201)
    end

    it 'creates the account with the correct data' do
      json = JSON.parse(response.body)
      account = Account.find(json['id'])
      attrs = account.attributes.slice(*%w(name organization_id))
      expect(attrs).to eq(body)
    end

    it 'returns the body with the correct body' do
      json = JSON.parse(response.body)
      account = Account.find(json['id'])
      expect(json).to eq(account_json(account))
    end
  end
end 