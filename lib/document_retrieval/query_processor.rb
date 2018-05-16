require 'fast_stemmer'

class QueryProcessor

  def initialize(user_query)
    @docs = DocumentCollection.new
    @query, @is_howto, @ext_list = simplify_query(user_query)
    @ranker = Ranker.new(@query, @docs)
  end

  def query
    index_to_url, init_index = get_index_to_url

    index_to_url[init_index].each do |url, pos_list|

      # filter by filename extension
      next if @ext_list.length != 0 && !@ext_list.include?(url[url.rindex('.')..url.length])

      h = {}
      t = 0
      cnt = 0
      f = true
      @query.each do |index|
        f &&= index_to_url[index].key? url
        break if f == false
        h[index] = index_to_url[index][url][1]
        t += index_to_url[index][url][0]
        cnt += index_to_url[index][url][1].length
      end
      if f
        @docs.add_doc(url)
        @docs.add_doc_tokens(url, h)
        @docs.add_doc_title_score(url, t)
        @docs.add_doc_count_score(url, cnt)
      end
    end

    @ranker.calculate_order_scores
    @ranker.calculate_sub_scores
    @ranker.get_selected_documents
    retrieve_pages
    @ranker.get_ranked_documents
  end

  private

  def retrieve_pages
    keys = @docs.get_selected_urls
    hash = DocumentRetrieval.retrieve_pages(keys)
    hash.each do |url, h|
      @docs.add_doc_title(url, h[:title])
      @docs.add_doc_html(url, h[:html])
      # Calculate special_score given the special divs and other features
      special_score = h[:score].gsub(/[^\d]/, ' ').split.inject(0){|s,x| s + x.to_i }
      @docs.add_doc_special_score(url, special_score, @is_howto)
    end
  end

  def get_index_to_url
    results = {}
    min_index_size = 200000
    min_index = ''
    @query.each do |index|
      retrieved = DocumentRetrieval.retrieve_index(index)
      results[index] = retrieved
      if min_index_size > retrieved.size
        min_index_size = retrieved.size
        min_index = index
      end
    end
    return results, min_index
  end

  def simplify_query(user_query)
    query = user_query

    ext_list = []
    ext_matches_list = []
    user_query.scan(/e: *[.][a-z]+/) do |match|
      ext_matches_list << match
      ext_list << match[match.index('.')..match.length]
    end
    ext_matches_list.each do |match|
      query = query.gsub(match, ' ')
    end

    is_howto = /how to .*/ =~ user_query.gsub(/[^a-z ]/i, ' ')
    query = query.gsub(/[^a-z ]/i, ' ').split()
    simple_query = []
    query.each do |word|
      token = Stemmer::stem_word(word.downcase)
      simple_query << token if !simple_query.include? word
    end
    simple_query = simple_query[2...simple_query.length] if is_howto
    return simple_query, is_howto, ext_list
  end

end
