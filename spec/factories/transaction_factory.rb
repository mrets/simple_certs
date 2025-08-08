FactoryBot.define do
  factory :transaction do
    event_type { 'certificate_issued' }
    transaction_id { "TXN-#{SecureRandom.hex(16)}-#{Time.current.to_i}" }
    success { true }
    
    trait :failed do
      success { false }
      error_message { 'An error occurred' }
    end
    
    trait :with_certificate do
      association :certificate
      association :generation
      association :generator
    end
    
    trait :with_certificate_quantity do
      association :certificate_quantity
      association :account
    end
    
    trait :certificate_split do
      event_type { 'certificate_split' }
      association :certificate_quantity
      association :new_certificate_quantity, factory: :certificate_quantity
      quantity_before { 1000 }
      quantity_after { 700 }
      quantity_changed { 300 }
      status_before { 'active' }
      status_after { 'active' }
    end
    
    trait :certificate_retired do
      event_type { 'certificate_retired' }
      association :certificate_quantity
      status_before { 'active' }
      status_after { 'retired' }
    end
    
    trait :transfer_initiated do
      event_type { 'certificate_transfer_initiated' }
      association :certificate_quantity
      association :target_organization, factory: :organization
      status_before { 'active' }
      status_after { 'intransit' }
    end
    
    trait :generation_created do
      event_type { 'generation_created' }
      association :generation
      association :organization
      quantity_after { 1000 }
    end
  end
end