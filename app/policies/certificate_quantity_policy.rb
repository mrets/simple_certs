class CertificateQuantityPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.joins(certificate: :generator)
           .where(generators: { organization_id: user.organization_id })
    end
  end

  def show?
    certificate_quantity_owned_by?
  end

  def create?
    certificate_quantity_owned_by?
  end

  def certificate_quantity_owned_by?
    @record.certificate.generator.organization_id == @user.organization_id
  end
end 