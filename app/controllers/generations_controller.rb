require 'ostruct'

class GenerationsController < ApplicationController
  def index
    @generations = Generation.all
    render 'index'
  end

  def show
    @generation = Generation.find(params[:id])
    render 'show'
  end

  def create
    @generation = Generation.new(generation_params)
    if @generation.save
      render 'show', status: :created
    else
      @errors = @generation.errors
      render 'errors'
    end
  end

  def generation_params
    params.permit(:start_date, :end_date, :quantity)
  end
end