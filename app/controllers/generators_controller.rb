require 'ostruct'

class GeneratorsController < ApplicationController
  def index
    @generators = GeneratorPolicy::Scope.new(current_user, Generator).resolve
    render 'index'
  end

  def show
    @generator = Generator.find(params[:id])
    authorize @generator

    render 'show'
  end

  def create
    @generator = Generator.new(generator_params)
    authorize @generator

    if @generator.save
      render 'show', status: :created
    else
      @errors = @generator.errors
      render 'errors'
    end
  end

  def generator_params
    params.permit(:name, :ext_id, :organization_id)
  end
end