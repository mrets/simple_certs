class Transaction < ApplicationRecord
  after_save :readonly!

  # When a Transaction is record, it must record the old and new states, even if not accepted.
  #
  # By adding these states, undoing a transaction would require "walking" back through transactions'
  # on a particular record, verifying it matches the "new" state, and performing an update to the "old" state.
  # This should be built as a new Rails operation to ensure revert transactions are also recorded.
  #
  # If a change is rejected, these details will also provide useful guide points for troubleshooting.
  
  def set_states(state_hash)
    self.old_state = state_hash[:old_state]
    self.new_state = state_hash[:new_state]
  end

  # Ensures that success and failure will close out and write the transaction the same way.

  def save_as_success
    self.completed = true
    self.recorded_at = Time.now
    save
  end

  def save_as_error
    self.completed = false
    self.recorded_at = Time.now
    save
  end
end
