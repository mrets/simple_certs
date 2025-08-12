FactoryBot.define do
  factory :transaction do
    request_uuid { 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' }
    request_user_id { 1 }
    initiated_at { DateTime.new(2025, 1, 1, 0, 0, 1) }
    recorded_at { DateTime.new(2025, 1, 1, 0, 0, 2) }
    resource { 'certificate_quantities' }
    action { 'retire' }
    completed { true }
    record_id { 1 }
    old_state { '{:field=>"old_value"}' }
    new_state { '{:field=>"new_value"}' }
  end
end