class TransactionLog < ApplicationRecord
  serialize :changeset, JSON
end