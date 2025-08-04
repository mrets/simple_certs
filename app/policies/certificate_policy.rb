class CertificatePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.joins(:generator)
           .where(generators: { organization_id: user.organization_id })
    end
  end

  def show?
    certificate_owned_by?
  end

  def create?
    certificate_owned_by?
  end

  def certificate_owned_by?
    @record.generator.organization_id == @user.organization_id
  end
end
