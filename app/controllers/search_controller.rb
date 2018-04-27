class SearchController < ApplicationController
  
  def index
    @query = params.has_key?(:q) ? params[:q] : ''
    redirect_to root_path if @query == ''
    @search_results = @query == '' ? [] : Search.query(@query)
  end

end
