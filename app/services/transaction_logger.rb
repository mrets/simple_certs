class TransactionLogger
  attr_reader :user, :organization, :request_id, :ip_address
  
  def initialize(user: nil, organization: nil, request_id: nil, ip_address: nil)
    @user = user
    @organization = organization || user&.organization
    @request_id = request_id || SecureRandom.uuid
    @ip_address = ip_address
  end
  
  def log_certificate_issuance(certificate, certificate_quantity)
    log_event(
      event_type: Transaction::EVENT_TYPES[:certificate_issued],
      certificate: certificate,
      certificate_quantity: certificate_quantity,
      generation: certificate.generation,
      account: certificate_quantity.account,
      quantity_after: certificate.quantity,
      metadata: {
        vintage_date: certificate.vintage_date,
        serial_number: certificate.sn_base,
        generator_id: certificate.generator_id
      }
    )
  end
  
  def log_certificate_split(original_cq, new_cq, split_quantity)
    log_event(
      event_type: Transaction::EVENT_TYPES[:certificate_split],
      certificate: original_cq.certificate,
      certificate_quantity: original_cq,
      new_certificate_quantity: new_cq,
      account: original_cq.account,
      quantity_before: original_cq.quantity + split_quantity,
      quantity_after: original_cq.quantity,
      quantity_changed: split_quantity,
      status_before: 'active',
      status_after: 'active',
      metadata: {
        original_id: original_cq.id,
        new_id: new_cq.id,
        split_quantity: split_quantity
      }
    )
  end
  
  def log_transfer_initiated(certificate_quantity, from_account, to_organization)
    log_event(
      event_type: Transaction::EVENT_TYPES[:certificate_transfer_initiated],
      certificate: certificate_quantity.certificate,
      certificate_quantity: certificate_quantity,
      account: from_account,
      target_organization: to_organization,
      quantity_before: certificate_quantity.quantity,
      quantity_after: certificate_quantity.quantity,
      status_before: 'active',
      status_after: 'intransit',
      metadata: {
        from_account_id: from_account.id,
        to_organization_id: to_organization.id
      }
    )
  end
  
  def log_transfer_accepted(certificate_quantity, to_account)
    log_event(
      event_type: Transaction::EVENT_TYPES[:certificate_transfer_accepted],
      certificate: certificate_quantity.certificate,
      certificate_quantity: certificate_quantity,
      account: certificate_quantity.account,
      target_account: to_account,
      quantity_before: certificate_quantity.quantity,
      quantity_after: certificate_quantity.quantity,
      status_before: 'intransit',
      status_after: 'active',
      metadata: {
        from_organization_id: certificate_quantity.account.organization_id,
        to_account_id: to_account.id
      }
    )
  end
  
  def log_transfer_cancelled(certificate_quantity)
    log_event(
      event_type: Transaction::EVENT_TYPES[:certificate_transfer_cancelled],
      certificate: certificate_quantity.certificate,
      certificate_quantity: certificate_quantity,
      account: certificate_quantity.account,
      quantity_before: certificate_quantity.quantity,
      quantity_after: certificate_quantity.quantity,
      status_before: 'intransit',
      status_after: 'active',
      metadata: {
        cancelled_by: user&.id
      }
    )
  end
  
  def log_internal_transfer(certificate_quantity, from_account, to_account)
    log_event(
      event_type: Transaction::EVENT_TYPES[:certificate_transfer_initiated],
      certificate: certificate_quantity.certificate,
      certificate_quantity: certificate_quantity,
      account: from_account,
      target_account: to_account,
      quantity_before: certificate_quantity.quantity,
      quantity_after: certificate_quantity.quantity,
      status_before: 'active',
      status_after: 'active',
      metadata: {
        transfer_type: 'internal',
        from_account_id: from_account.id,
        to_account_id: to_account.id
      }
    )
  end
  
  def log_retirement(certificate_quantity)
    log_event(
      event_type: Transaction::EVENT_TYPES[:certificate_retired],
      certificate: certificate_quantity.certificate,
      certificate_quantity: certificate_quantity,
      account: certificate_quantity.account,
      quantity_before: certificate_quantity.quantity,
      quantity_after: certificate_quantity.quantity,
      status_before: 'active',
      status_after: 'retired',
      metadata: {
        retired_by: user&.id,
        retirement_date: Time.current
      }
    )
  end
  
  def log_generation_created(generation)
    log_event(
      event_type: Transaction::EVENT_TYPES[:generation_created],
      # Don't set the generation association, just store the ID in metadata
      organization: generation.generator.organization,
      quantity_after: generation.quantity,
      metadata: {
        generation_id: generation.id,
        generator_id: generation.generator_id,
        start_date: generation.start_date,
        end_date: generation.end_date
      }
    )
  end
  
  def log_error(event_type, error, **attributes)
    log_event(
      event_type: event_type,
      success: false,
      error_message: error.message,
      metadata: {
        error_class: error.class.name,
        backtrace: error.backtrace&.first(5)
      }.merge(attributes[:metadata] || {}),
      **attributes.except(:metadata)
    )
  end
  
  private
  
  def log_event(event_type:, success: true, **attributes)
    Transaction.create!(
      event_type: event_type,
      success: success,
      user: user,
      organization: organization,
      request_id: request_id,
      ip_address: ip_address,
      **attributes
    )
  end
end