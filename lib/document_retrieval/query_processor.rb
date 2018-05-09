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
      @docs.add_doc_html(url, snippet(h[:html],@query))
      # Calculate special_score given the special divs and other features
      # TODO add special score to some pages for special queries
      special_score = h[:score].gsub(/[^\d]/, ' ').split.inject(0){|s,x| s + x.to_i }
      @docs.add_doc_special_score(url, special_score)
    end
  end

  def snippet(html,query)
    return_html = []
    queue = []
    least = ""
    started = false
    hash_quey = Hash[query.collect { |v| [v, v] }]

    html.split().each do |word|

      stemmed_word = stemmer(word.downcase)
      downcased_word = word.downcase

      if downcased_word == queue[0]
        len = queue.size
        least = queue.join(' ')
        while queue[0] == downcased_word do
          queue.pop
        end
      end
          
      if hash_quey[stemmed_word] == stemmed_word
        queue << downcased_word
        started = true
      end

      if downcased_word != queue[queue.size-1] and started
        queue << word.downcase
      end
    end
    
    least = queue.join(' ') if least.length == 0
    
    least.split().each do |word|
      stemmed_word = stemmer(word)
      if hash_quey[stemmed_word] == stemmed_word
        return_html << '<b>' + word +'</b>'
      else
        return_html << word
      end
    end

    return_html.join(' ')

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
    query = user_query.gsub(/[^a-z ]/i, ' ').split()
    simple_query = []
    query.each do |word|
      token = stemmer(word.downcase)
      simple_query << token if !simple_query.include? word
    end
    simple_query
  end

  def stemmer(word)
    Stemmer::stem_word(word)
  end

end
