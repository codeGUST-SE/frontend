require 'will_paginate/array'
class SearchController < ApplicationController
  
  def index
    @query = params.has_key?(:q) ? params[:q] : ''
    @page = params.has_key?(:q) ? params[:q] : ''
    redirect_to root_path if @query == ''
    results = @query == '' ? [] : Search.query(@query)
    
    @search_results = results.paginate(:page => 3, :per_page => 20)
  end

end
