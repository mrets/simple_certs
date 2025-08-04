class GeneratorPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.where(organization_id: user.organization_id)
    end
  end

  def show?
    generator_owned_by?
  end

  def create?
    generator_owned_by?
  end

  def generator_owned_by?
    @record.organization_id == @user.organization_id
  end
end
