FactoryBot.define do
  factory :certificate do
    sn_base { 'CERT001' }
    quantity { 100 }
    generation_entry_id { 1 }
  end
end 