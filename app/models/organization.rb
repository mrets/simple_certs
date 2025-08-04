class Organization < ApplicationRecord
  has_many :accounts
  has_many :generators
  has_many :users

  belongs_to :default_account, class_name: "Account", foreign_key: :default_account_id, optional: true

  after_create :create_default_account

  def create_default_account
    self.default_account = Account.create(name: "default", organization: self)
    save
  end
end
