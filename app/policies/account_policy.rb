class AccountPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.where(organization_id: user.organization_id)
    end
  end

  def show?
    account_owned_by?
  end

  def create?
    account_owned_by?
  end

  def account_owned_by?
    @record.organization_id == @user.organization_id
  end
end 