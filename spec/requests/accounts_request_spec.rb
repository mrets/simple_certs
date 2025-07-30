require 'rails_helper'
require 'ostruct'

RSpec.describe 'Accounts', type: :request do
  let!(:organization) { create(:organization) }
  let!(:other_organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:account) { organization.default_account }
  let(:other_account) { other_organization.default_account }

  let(:json_headers) {
    { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  }
  let(:user_header) {
    { 'X-Api-Key' => user.api_key }
  }
  let(:headers) {
    json_headers.merge(user_header)
  }

  def account_json(account)
    {
      'id' => account.id,
      'name' => account.name,
      'organization_id' => account.organization_id,
    }
  end

  context 'index' do
    before do
      get '/accounts', headers: headers
    end

    it 'has a 200 status' do
      expect(response.status).to eq(200)
    end

    it 'returns accounts' do
      json = JSON.parse(response.body)
      expect(json).to eq(
        {
          'accounts' => [ account_json(account) ]
        }
      )
    end
  end

  context 'show' do
    context "when accessing account that is associated with user's organization" do
      it 'returns an account' do
        get "/accounts/#{organization.default_account_id}", headers: headers
        json = JSON.parse(response.body)
        expect(json).to eq(account_json(account))
      end
    end

    context "when accessing account that is not associated with user's organization" do
      it 'returns an unauthorized status' do
        get "/accounts/#{other_account.id}", headers: headers
        expect(response.code).to eq('401')
      end
    end
  end

  context 'create' do
    let(:body) {
      {
        'name' => 'Test Account',
        'organization_id' => organization.id
      }
    }

    before do
      post '/accounts', headers: headers, params: body.to_json
    end

    context "when creating account that is associated with the user's organization" do
      it 'creates an account' do
        expect(Account.count).to eq(3)
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

    context "when creating account that is NOT associated with the user's organization" do
      let(:body) {
        {
          'name' => 'Test Account',
          'organization_id' => other_organization.id
        }
      }

      it 'returns an unauthorized status' do
        expect(response.code).to eq('401')
      end
    end
  end
end 