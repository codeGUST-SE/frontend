require 'fast_stemmer'

class QueryProcessor

  def initialize(user_query)
    @docs = DocumentCollection.new
    @query = simplify_query(user_query)
    @ranker = Ranker.new(@query, @docs)
  end

  def query
    index_to_url, init_index = get_index_to_url

    index_to_url[init_index].each do |url, pos_list|
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
    @ranker.get_ranked_documents
  end

  private

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
    query = user_query.gsub(/[^a-z ]/i, ' ').split()
    simple_query = []
    query.each do |word|
      token = Stemmer::stem_word(word.downcase)
      simple_query << token if !simple_query.include? word
    end
    simple_query
  end

end
