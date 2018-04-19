class ApplicationController < ActionController::Base

  def home
    render html: "CodeGUST home page"
  end

end
