FactoryBot.define do
  factory :certificate_quantity do
    quantity { 50 }
    account
    certificate

    trait :stale do
      to_organization { create(:organization) }
      status { 'intransit' }
      status_changed_at { 25.hours.ago }
    end
  end
end
