class TransactionJob < ApplicationJob
  def perform(transaction, data)
    change = Transaction.new(transaction)
    change.record_id = data[:id]

    begin
      case change.resource
        # Routing for any resource with a job queue
        when 'certificate_quantities'
          certificate_quantity = CertificateQuantity.find(data[:id])
          mod_states = case change.action
            when 'retire' then certificate_quantity.retire
            when 'transfer' then certificate_quantity.transfer(data[:account_id], data[:organization_id])
            when 'cancel_transfer' then certificate_quantity.cancel_transfer
            when 'accept_transfer' then certificate_quantity.accept_transfer(data[:account_id])
            when 'split'
              split_states = certificate_quantity.split(data[:quantity])
              puts split_states
              split_transaction = change.dup
              split_transaction.record_id = split_states.delete(:id)
              split_transaction.set_states(split_states[:split_record])
              split_transaction.save_as_success
              split_states[:original_record]
            else raise("Transaction not recognized")
          end
          change.set_states(mod_states)
          certificate_quantity
        else raise("Resource not recognized")
      end
      change.save_as_success
    rescue
      change.save_as_error
    end
  end
end