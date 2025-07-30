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

# Organization 2
org2 = Organization.find_or_create_by!(name: "Organization Two") do |org|
  puts "Created Organization Two"
end

user2 = User.find_or_create_by!(api_key: "xyz") do |user|
  user.organization = org2
  puts "Created user xyz"
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

puts "Seed data creation completed!"
puts "Organization One: #{org1.name} with user #{user1.api_key}"
puts "Organization Two: #{org2.name} with user #{user2.api_key}"
