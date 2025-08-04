FactoryBot.define do
  factory :certificate_quantity do
    quantity { 50 }
    certificate { create(:certificate) }
  end
end
