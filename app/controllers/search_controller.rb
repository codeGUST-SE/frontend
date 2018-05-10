class SearchController < ApplicationController
  
  def index
    @query = params.has_key?(:q) ? params[:q] : ''
    redirect_to root_path if @query == ''
    # puts Search.query(@query)[23].snippet
    @search_results = @query == '' ? [] : Search.query(@query)
  end

end
