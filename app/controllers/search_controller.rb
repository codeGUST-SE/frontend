class SearchController < ApplicationController

  def index
    @search_results = Search.query('alaska')
  end

end
