class Search

  def self.query(user_query)
    Ranker.new(user_query).query
  end

end
