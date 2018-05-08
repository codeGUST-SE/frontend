class ApplicationController < ActionController::Base

  def home
  end

  def mobile
    puts params
    @query = params.has_key?(:q) ? params[:q] : ''
    redirect_to root_path if @query == ''
    render json: @query == '' ? [] : Search.query(@query)
  end

end
