class SearchController < ApplicationController
  
  def index
    @query = params.has_key?(:q) ? params[:q] : ''
    redirect_to root_path if @query == ''
    beginning = Time.now
    returnValue = Search.query(@query)
    @benchmark = (Time.now - beginning).round(2)
    @search_results = @query == '' ? [] : returnValue
  end

end
