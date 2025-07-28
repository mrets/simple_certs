class GeneratorsController < ApplicationController
  def index
    @generators = Generator.all
  end
end