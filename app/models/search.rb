class Search

  def self.query(user_query)
    QueryProcessor.new(user_query).query
  end

end
