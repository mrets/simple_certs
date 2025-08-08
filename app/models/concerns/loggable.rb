module Loggable
  extend ActiveSupport::Concern

  included do
    after_create { log_transaction("create") }
    after_update { log_transaction("update") }
    after_destroy { log_transaction("destroy") }
  end

  private
    def log_transaction(event)
      Transaction.create!(
        record_type: self.class.name,
        record_id: self.id,
        event: event
      )
    end
end