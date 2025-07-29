json.certificates @certificates do |certificate|
  json.partial! 'certificate', certificate: certificate
end 