# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating organizations and associated data..."

# Organization 1
org1 = Organization.find_or_create_by!(name: "Organization One") do |org|
  puts "Created Organization One"
end

user1 = User.find_or_create_by!(api_key: "abcd") do |user|
  user.organization = org1
  puts "Created user abcd"
end

account1 = Account.find_or_create_by!(name: "Account One") do |account|
  account.organization = org1
  puts "Created Account One"
end

generator1 = Generator.find_or_create_by!(name: "Generator One") do |generator|
  generator.organization = org1
  generator.ext_id = "GEN001"
  puts "Created Generator One"
end

generation1 = Generation.find_or_create_by!(start_date: Date.new(2025, 1, 1), generator: generator1) do |generation|
  generation.end_date = Date.new(2025, 1, 31)
  generation.quantity = 100
  puts "Created Generation One"
end

certificate1 = Certificate.find_or_create_by!(sn_base: "CERT001") do |certificate|
  certificate.generator = generator1
  certificate.generation = generation1
  certificate.quantity = 100
  puts "Created Certificate One"
end

certificate_quantity1 = CertificateQuantity.find_or_create_by!(certificate: certificate1) do |cq|
  cq.quantity = 100
  cq.account = account1
  puts "Created Certificate Quantity One"
end

# Organization 2
org2 = Organization.find_or_create_by!(name: "Organization Two") do |org|
  puts "Created Organization Two"
end

user2 = User.find_or_create_by!(api_key: "xyz") do |user|
  user.organization = org2
  puts "Created user xyz"
end

account2 = Account.find_or_create_by!(name: "Account Two") do |account|
  account.organization = org2
  puts "Created Account Two"
end

generator2 = Generator.find_or_create_by!(name: "Generator Two") do |generator|
  generator.organization = org2
  generator.ext_id = "GEN002"
  puts "Created Generator Two"
end

generation2 = Generation.find_or_create_by!(start_date: Date.new(2025, 1, 1), generator: generator2) do |generation|
  generation.end_date = Date.new(2025, 1, 31)
  generation.quantity = 100
  puts "Created Generation Two"
end

certificate2 = Certificate.find_or_create_by!(sn_base: "CERT002") do |certificate|
  certificate.generator = generator2
  certificate.generation = generation2
  certificate.quantity = 100
  puts "Created Certificate Two"
end

certificate_quantity2 = CertificateQuantity.find_or_create_by!(certificate: certificate2) do |cq|
  cq.quantity = 100
  cq.account = account2
  puts "Created Certificate Quantity Two"
end

org1.update(default_account: account1)
org2.update(default_account: account2)

puts "Seed data creation completed!"
puts "Organization One: #{org1.name} with user #{user1.api_key}"
puts "Organization Two: #{org2.name} with user #{user2.api_key}"
