FactoryBot.define do
  factory :generation do
    start_date { Date.new(2025, 1, 1) }
    end_date   { Date.new(2025, 1, 31) }
    quantity   { 100 }
    generator  { create(:generator) }
  end
end
