require 'fast_stemmer'

class DocumentCollection

  def initialize
    @docs = {}

    @selected_urls = []

    @min_order_score = 0.0
    @min_title_score = 0.0
    @min_count_score = 0.0
    @min_sub_score = 0.0
    @min_special_score_gh = 0.0
    @min_special_score_so = 0.0
    @min_special_score_tp = 0.0
    @min_special_score_gg = 0.0

    @max_order_score = 0.0
    @max_title_score = 0.0
    @max_count_score = 0.0
    @max_sub_score = 0.0
    @max_special_score_gh = 0.0
    @max_special_score_so = 0.0
    @max_special_score_tp = 0.0
    @max_special_score_gg = 0.0
  end

  private

  PRECISION = 2

  GH_URL = 0
  SO_URL = 1
  TP_URL = 2
  GG_URL = 3


  class Document

    SNIPPET_LENGTH_MAX = 800
    SNIPPET_WORD_MIN = 30

    W = { :order_score => 4.0, :sub_score => 2.5, :title_score => 2.0, :count_score => 0.5, :special_score => 1.0}

    attr_accessor :order_score, :sub_score, :title_score, :count_score, :special_score
    attr_accessor :url, :title, :html
    attr_accessor :tokens

    def initialize(url)
      @url = url
      @title = ''
      @html = ''
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

    def snippet
      html = @html.split()
      query = tokens.keys

      cbq = CurrentBlockQueue.new(query)

      html.each_with_index do |word, i|
        words = word.gsub(/[^a-z ]/i, ' ').split()
        words.each do |w|
          stemmed_word = Stemmer::stem_word(w.downcase)
          cbq.add(stemmed_word, i) if query.include? stemmed_word
        end
      end

      smallest_window = cbq.smallest_window

      if smallest_window[1] - smallest_window[0] < SNIPPET_WORD_MIN
        smallest_window[0] = smallest_window[0] - 5
        smallest_window[0] = 0 if smallest_window[0] < 0
        smallest_window[1] = smallest_window[1] + 5
        smallest_window[1] = html.length-1 if smallest_window[1] > html.length-1
      end

      smallest_window = [0, [SNIPPET_WORD_MIN, html.length-1].min] if smallest_window == []

      return_html = ' '
      for i in (smallest_window[0]..smallest_window[1])
        words = html[i].gsub(/[^a-z ]/i, ' ').split

        s = 0
        words.each do |w|
          stemmed_word = Stemmer::stem_word(w.downcase)
          pos = html[i][s...html[i].length].index(w) + s
          return_html += html_tags_removal(html[i][s...pos])

          if query.include? stemmed_word
            return_html += '<b>' + html_tags_removal(w) + '</b>'
          else
            return_html += html_tags_removal(w)
          end
          s = pos + w.length
        end
        return_html += html_tags_removal(html[i][s...html[i].length]) + ' '
        break if return_html.length > SNIPPET_LENGTH_MAX
      end
      return_html
    end

    def html_tags_removal(word)
      word = word.gsub('<', '&#60;') if word.include?('<')
      word = word.gsub('>', '&#62;') if word.include?('>')
      word
    end

    def hash
      @url
    end

  end

  def url_type(url)
    if /github.com/ =~ url
      return GH_URL
    elsif /stackoverflow.com/ =~ url
      return SO_URL
    elsif /tutorialspoint.com/ =~ url
      return TP_URL
    elsif /geeksforgeeks.org/ =~ url
      return GG_URL
    end
  end

  public

  def add_doc(url)
    @docs[url] = Document.new(url) if !@docs.key?url
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

  def add_doc_special_score(url, special_score, is_howto)
    s = Math::log(special_score)
    @docs[url].special_score = s.to_f

    # special_scores are going to be normalized separately for each url type
    type = url_type(url)
    if type == GH_URL
      @min_special_score_gh = [@min_special_score_gh, s].min.to_f
      @max_special_score_gh = [@max_special_score_gh, s].max.to_f
    elsif type == SO_URL
      @min_special_score_so = [@min_special_score_so, s].min.to_f
      @max_special_score_so = [@max_special_score_so, s].max.to_f
    elsif type == TP_URL
      s = 1 if is_howto
      @min_special_score_tp = [@min_special_score_tp, s].min.to_f
      @max_special_score_tp = [@max_special_score_tp, s].max.to_f
    elsif type == GG_URL
      s = 1 if is_howto
      @min_special_score_gg = [@min_special_score_gg, s].min.to_f
      @max_special_score_gg = [@max_special_score_gg, s].max.to_f
    end
  end

  def get_docs
    @docs
  end

  def get_selected_urls
    @selected_urls
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
      doc.order_score = 0.0 if doc.order_score.nan?
      doc.sub_score = ((doc.sub_score - @min_sub_score)/(@max_sub_score - @min_sub_score)).round(PRECISION)
      doc.sub_score = 0.0 if doc.sub_score.nan?
      doc.title_score = ((doc.title_score - @min_title_score)/(@max_title_score - @min_title_score)).round(PRECISION)
      doc.title_score = 0.0 if doc.title_score.nan?
      doc.count_score = ((doc.count_score - @min_count_score)/(@max_count_score - @min_count_score)).round(PRECISION)
      doc.count_score = 0.0 if doc.count_score.nan?
    end
  end

  def normalize_selected_scores()
    @selected_urls.each do |url|
      doc = @docs[url]

      # Normalize special_score separately for each url type separately
      type = url_type(url)
      if type == GH_URL
        doc.special_score = ((doc.special_score - @min_special_score_gh)/(@max_special_score_gh - @min_special_score_gh)).round(PRECISION)
      elsif type == SO_URL
        doc.special_score = ((doc.special_score - @min_special_score_so)/(@max_special_score_so - @min_special_score_so)).round(PRECISION)
      elsif type == TP_URL
        doc.special_score = ((doc.special_score - @min_special_score_tp)/(@max_special_score_tp - @min_special_score_tp)).round(PRECISION)
      elsif type == GG_URL
        doc.special_score = ((doc.special_score - @min_special_score_gg)/(@max_special_score_gg - @min_special_score_gg)).round(PRECISION)
      end
      doc.special_score = 0.0 if doc.special_score.nan?
    end
  end

end
