class GenerationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user

      scope.for_organization(user.organization)
    end
  end

  def show?
    generator_owned_by?
  end

  def create?
    generator_owned_by?
  end

  def generator_owned_by?
    @record.generator.organization_id == @user.organization_id
  end
end

class PostPolicy
  attr_reader :user, :post

  def initialize(user, post)
    @user = user
    @post = post
  end

  def update?
    user.admin? || !post.published?
  end
end