class Transaction < ApplicationRecord
  after_save :readonly!

  def set_states(state_hash)
    self.old_state = state_hash[:old_state]
    self.new_state = state_hash[:new_state]
  end

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
