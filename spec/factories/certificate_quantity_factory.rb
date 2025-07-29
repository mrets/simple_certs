FactoryBot.define do
  factory :certificate_quantity do
    sn_start { 1000 }
    quantity { 50 }
    certificate { create(:certificate) }
  end
end 