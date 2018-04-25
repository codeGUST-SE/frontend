class Document

  W = { :order_score => 1.0, :title_score => 1.0, :count_score => 1.0 }

  attr_accessor :order_score, :title_score, :count_score, :url

  def initialize(url, order_score = 0.0, title_score = 0.0, count_score = 0.0)
    @url = url
    @order_score = order_score
    @title_score = title_score
    @count_score = Math::log(count_score)
  end

  def total
    W[:order_score] * @order_score +
    W[:title_score] * @title_score +
    W[:count_score] * @count_score
  end

  def hash
    @url
  end

  def <=>(other)
    @total <=> other.total
  end

end
