#!/usr/bin/env ruby

# Script to test transaction logging and concurrency control
# Run with: rails runner test_transaction_logging.rb

puts "Testing Transaction Logging and Concurrency Control"
puts "=" * 50

# Create test data
org = Organization.create!(name: "Test Organization #{SecureRandom.hex(4)}")
user = User.create!(organization: org, api_key: SecureRandom.hex)
generator = Generator.create!(name: "Test Generator", organization: org)

puts "\n1. Testing Certificate Issuance with Logging"
puts "-" * 30

# Create a generation which triggers certificate issuance
generation = Generation.create!(
  generator: generator,
  start_date: 1.month.ago,
  end_date: 1.week.ago,
  quantity: 1000
)

# Check transaction log
issuance_logs = Transaction.where(event_type: 'certificate_issued').last
if issuance_logs
  puts "✓ Certificate issuance logged successfully"
  puts "  Transaction ID: #{issuance_logs.transaction_id}"
  puts "  Quantity: #{issuance_logs.quantity_after}"
else
  puts "✗ No issuance log found"
end

puts "\n2. Testing Split Operation with Logging"
puts "-" * 30

# Get the certificate quantity created
cq = generation.certificate.certificate_quantities.first
logger = TransactionLogger.new(user: user, organization: org)

original_quantity = cq.quantity
split_amount = 300

new_cq = cq.split(split_amount, logger: logger)

split_log = Transaction.where(event_type: 'certificate_split').last
if split_log && split_log.quantity_before == original_quantity
  puts "✓ Split operation logged successfully"
  puts "  Original quantity: #{split_log.quantity_before}"
  puts "  After split: #{split_log.quantity_after}"
  puts "  New quantity created: #{split_log.quantity_changed}"
else
  puts "✗ Split log not found or incorrect"
end

puts "\n3. Testing Transfer Operations with Logging"
puts "-" * 30

# Create another organization for transfer
other_org = Organization.create!(name: "Other Organization #{SecureRandom.hex(4)}")

# Initiate external transfer
cq.reload
cq.initiate_transfer(other_org, logger: logger)

transfer_log = Transaction.where(event_type: 'certificate_transfer_initiated').last
if transfer_log && transfer_log.status_after == 'intransit'
  puts "✓ Transfer initiation logged successfully"
  puts "  Status changed: #{transfer_log.status_before} -> #{transfer_log.status_after}"
  puts "  Target org: #{transfer_log.target_organization_id}"
else
  puts "✗ Transfer log not found"
end

# Cancel the transfer
cq.reload
cq.cancel_transfer(logger: logger)

cancel_log = Transaction.where(event_type: 'certificate_transfer_cancelled').last
if cancel_log && cancel_log.status_after == 'active'
  puts "✓ Transfer cancellation logged successfully"
  puts "  Status reverted: #{cancel_log.status_before} -> #{cancel_log.status_after}"
else
  puts "✗ Cancel log not found"
end

puts "\n4. Testing Retirement with Logging"
puts "-" * 30

cq.reload
cq.retire(logger: logger)

retire_log = Transaction.where(event_type: 'certificate_retired').last
if retire_log && retire_log.status_after == 'retired'
  puts "✓ Retirement logged successfully"
  puts "  Status changed: #{retire_log.status_before} -> #{retire_log.status_after}"
else
  puts "✗ Retirement log not found"
end

puts "\n5. Testing Concurrency Protection"
puts "-" * 30

# Create a new certificate quantity for concurrency test
new_gen = Generation.create!(
  generator: generator,
  start_date: 2.months.ago,
  end_date: 1.month.ago,
  quantity: 500
)
test_cq = new_gen.certificate.certificate_quantities.first

# Simulate concurrent access
begin
  # Start a transaction and lock the record
  ActiveRecord::Base.transaction do
    test_cq.lock!
    
    # Try to access from another thread (will be blocked)
    thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        begin
          test_cq_copy = CertificateQuantity.find(test_cq.id)
          test_cq_copy.split(100, logger: logger)
          puts "✗ Concurrent modification succeeded (should have been blocked)"
        rescue ActiveRecord::StatementInvalid => e
          if e.message.include?("database is locked")
            puts "✓ Concurrent modification blocked successfully"
            puts "  Error: #{e.message[0..50]}..."
          else
            raise
          end
        end
      end
    end
    
    # Hold the lock for a moment
    sleep 0.5
    
    # Complete the first operation
    test_cq.split(50, logger: logger)
  end
  
  thread.join
rescue => e
  puts "Error during concurrency test: #{e.message}"
end

puts "\n6. Testing Append-Only Constraint"
puts "-" * 30

# Try to update a transaction record (should fail)
begin
  last_transaction = Transaction.last
  last_transaction.update!(event_type: 'modified')
  puts "✗ Transaction was modified (should be prevented)"
rescue => e
  puts "✓ Transaction update prevented"
  puts "  Error: #{e.message}"
end

# Try to delete a transaction record (should fail)
begin
  Transaction.last.destroy!
  puts "✗ Transaction was deleted (should be prevented)"
rescue => e
  puts "✓ Transaction deletion prevented"
  puts "  Error: #{e.message}"
end

puts "\n7. Transaction Log Summary"
puts "-" * 30

total_logs = Transaction.count
successful = Transaction.successful.count
failed = Transaction.failed.count

puts "Total transaction logs: #{total_logs}"
puts "Successful: #{successful}"
puts "Failed: #{failed}"

puts "\nEvents by type:"
Transaction.group(:event_type).count.each do |event_type, count|
  puts "  #{event_type}: #{count}"
end

puts "\n" + "=" * 50
puts "Transaction logging test completed!"