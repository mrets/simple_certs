FactoryBot.define do
  factory :account do
    name { 'Test Account' }
    organization { create :organization }
  end
end 