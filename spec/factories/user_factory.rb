FactoryBot.define do
  factory :user do
    api_key { 'abcd' }
    organization { create(:organization) }
  end
end
