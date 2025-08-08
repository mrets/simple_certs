require_relative 'config/environment'

# Clear existing data
Transaction.delete_all
CertificateQuantity.delete_all
Certificate.delete_all
Generation.delete_all
Generator.delete_all
Account.delete_all
User.delete_all
Organization.delete_all

# Create test data
organization = Organization.create!(name: 'Test Org')
user = User.create!(api_key: 'test-key-123', organization: organization)
generator = Generator.create!(name: 'Test Generator', organization: organization)

puts "Initial Transaction count: #{Transaction.count}"

generation = Generation.create!(
  generator: generator,
  start_date: Date.today - 60.days,
  end_date: Date.today - 30.days,
  quantity: 1000
)

puts "After creating generation, Transaction count: #{Transaction.count}"
Transaction.all.each do |t|
  puts "  - #{t.event_type}: #{t.id}"
end

certificate = generation.certificate
puts "Certificate created: #{certificate.id}"
puts "After getting certificate, Transaction count: #{Transaction.count}"
Transaction.all.each do |t|
  puts "  - #{t.event_type}: #{t.id}"
end

certificate_quantity = certificate.certificate_quantities.first
puts "Certificate quantity: #{certificate_quantity.id}"
puts "After getting certificate_quantity, Transaction count: #{Transaction.count}"

logger = TransactionLogger.new(user: user, organization: organization)
logger.log_certificate_issuance(certificate, certificate_quantity)

puts "After logging issuance, Transaction count: #{Transaction.count}"
Transaction.all.each do |t|
  puts "  - #{t.event_type}: #{t.id}"
end
