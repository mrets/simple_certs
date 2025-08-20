FactoryBot.define do
  factory :certificate do
    sn_base { 'CERT001' }
    quantity { 100 }
    generator { create(:generator) }
    generation
  end
end
