class DocumentCollection

  PRECISION = 2

  def initialize
    @docs = {}
    @min_order_score = 10000000000.0
    @min_title_score = 10000000000.0
    @min_count_score = 10000000000.0
    @min_special_score = 10000000000.0
    @min_sub_score = 10000000000.0

    @max_order_score = -1.0
    @max_title_score = -1.0
    @max_count_score = -1.0
    @max_special_score = -1.0
    @max_sub_score = -1.0
  end

  private

  class Document

    W = { :order_score => 1.0, :sub_score => 1.0, :title_score => 1.0, :count_score => 1.0, :special_score => 1.0}

    attr_accessor :order_score, :sub_score, :title_score, :count_score, :special_score
    attr_accessor :url, :title, :html
    attr_accessor :tokens

    def initialize(url)
      @url = url
      @order_score = 0.0
      @sub_score = 0.0
      @title_score = 0.0
      @count_score = 0.0
      @special_score = 0.0
    end

    def total
      (W[:order_score] * @order_score +
      W[:sub_score] * @sub_score +
      W[:title_score] * @title_score +
      W[:count_score] * @count_score +
      W[:special_score] * @special_score).round(PRECISION)
    end

    def hash
      @url
    end

  end

  public

  def add_doc(url)
    @docs[url] = Document.new(url) if !@docs.key?url
  end

  def add_doc_special_score(url, special_score)
    @docs[url].special_score = special_score
    @min_special_score, @max_special_score = [@min_special_score, @max_special_score, special_score].minmax
  end

  def add_doc_title(url, title)
    @docs[url].title = title
  end

  def add_doc_html(url, html)
    @docs[url].html = html
  end

  def add_doc_tokens(url, tokens_hash)
    @docs[url].tokens = tokens_hash
  end

  def add_doc_title_score(url, title_score)
    @docs[url].title_score = title_score.to_f
    @min_title_score = [@min_title_score, title_score].min.to_f
    @max_title_score = [@max_title_score, title_score].max.to_f
  end

  def add_doc_count_score(url, count_score)
    s = Math::log(count_score)
    @docs[url].count_score = s.to_f
    @min_count_score = [@min_count_score, s].min.to_f
    @max_count_score = [@max_count_score, s].max.to_f
  end

  def add_doc_order_score(url, order_score)
    @docs[url].order_score = order_score.to_f
    @min_order_score = [@min_order_score, order_score].min.to_f
    @max_order_score = [@max_order_score, order_score].max.to_f
  end

  def add_doc_sub_score(url, sub_score)
    @docs[url].sub_score = sub_score.to_f
    @min_sub_score = [@min_sub_score, sub_score].min.to_f
    @max_sub_score = [@max_sub_score, sub_score].max.to_f
  end

  def get_docs
    @docs
  end

  def get_doc_tokens(url)
    @docs[url].tokens
  end

  def get_doc_title_score(url)
    @docs[url].title_score
  end

  def get_doc_order_score(url)
    @docs[url].order_score
  end

  def normalize_scores()
    @docs.each do |url, doc|
      doc.order_score = ((doc.order_score - @min_order_score)/(@max_order_score - @min_order_score)).round(PRECISION)
      doc.sub_score = ((doc.sub_score - @min_sub_score)/(@max_sub_score - @min_sub_score)).round(PRECISION)
      doc.title_score = ((doc.title_score - @min_title_score)/(@max_title_score - @min_title_score)).round(PRECISION)
      doc.count_score = ((doc.count_score - @min_count_score)/(@max_count_score - @min_count_score)).round(PRECISION)
      doc.special_score = ((doc.special_score - @min_special_score)/(@max_special_score - @min_special_score)).round(PRECISION)
    end
  end

end
