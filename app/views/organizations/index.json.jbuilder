json.organizations @organizations do |organization|
  json.partial! "organization", organization: organization
end
