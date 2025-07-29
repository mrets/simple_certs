require 'ostruct'

class GeneratorsController < ApplicationController
  def index
    @generators = Generator.all
    render 'index'
  end

  def show
    @generator = Generator.find(params[:id])
    render 'show'
  end

  def create
    @generator = Generator.new(generator_params)
    if @generator.save
      render 'show', status: :created
    else
      @errors = @generator.errors
      render 'errors'
    end
  end

  def generator_params
    params.permit(:name, :ext_id)
  end
end