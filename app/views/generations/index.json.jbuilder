json.generations @generations do |generation|
  json.partial! "generation", generation: generation
end
