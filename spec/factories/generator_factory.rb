FactoryBot.define do
  factory :generator do
    name { 'Test Generator' }
    ext_id { 'GEN001' }
    organization { create(:organization) }
  end
end 