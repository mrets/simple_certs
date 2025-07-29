require 'ostruct'

class AccountsController < ApplicationController
  def index
    @accounts = AccountPolicy::Scope.new(current_user, Account).resolve
    render 'index'
  end

  def show
    @account = Account.find(params[:id])
    authorize @account

    render 'show'
  end

  def create
    @account = Account.new(account_params)
    authorize @account

    if @account.save
      render 'show', status: :created
    else
      @errors = @account.errors
      render 'errors'
    end
  end

  def account_params
    params.permit(:name, :organization_id)
  end
end