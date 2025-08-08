#!/usr/bin/env ruby

# Debug script for generation creation
puts "Debugging Generation Creation"
puts "=" * 50

# Create test data
org = Organization.create!(name: "Debug Org #{SecureRandom.hex(4)}")
gen = Generator.create!(name: "Debug Gen", organization: org)

puts "\nCreating generation..."
puts "Generator ID: #{gen.id}"
puts "Organization ID: #{org.id}"

begin
  g = Generation.create!(
    generator: gen,
    start_date: 1.month.ago,
    end_date: 1.week.ago,
    quantity: 100
  )
  puts "✓ Generation created successfully: #{g.id}"
  
  # Check transaction logs
  logs = Transaction.where(event_type: 'generation_created').last
  if logs
    puts "✓ Transaction log created: #{logs.transaction_id}"
  else
    puts "✗ No transaction log found"
  end
  
rescue => e
  puts "✗ Error: #{e.message}"
  puts "\nBacktrace:"
  puts e.backtrace.first(10).join("\n")
  
  # Check validation errors
  if e.is_a?(ActiveRecord::RecordInvalid)
    puts "\nValidation errors:"
    e.record.errors.full_messages.each do |msg|
      puts "  - #{msg}"
    end
  end
end

puts "\n" + "=" * 50