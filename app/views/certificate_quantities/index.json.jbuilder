json.certificate_quantities @certificate_quantities do |certificate_quantity|
  json.partial! 'certificate_quantity', certificate_quantity: certificate_quantity
end 