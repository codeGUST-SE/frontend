class SearchController < ApplicationController

  def index
    @query = params.has_key?(:q) ? params[:q] : ''
    @search_results = @query == '' ? [] : Search.query(@query)
  end

end
