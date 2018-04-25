require 'fast_stemmer'
require 'pqueue'

class Ranker

  MAX_RESULT_NUMBER = 100

  def initialize(user_query)
    @query = simplify_query(user_query)
  end

  def query
    index_to_url, init_index = get_index_to_url

    url_to_pos = {}
    index_to_url[init_index].each do |url, pos_list|
      h = []
      f = true
      @query.each do |index|
        f &&= index_to_url[index].key? url
        break if f == false
        h << index_to_url[index][url][1]
      end
      url_to_pos[url] = h if f
    end

    # calculate title_score
    title_scores = {}
    url_to_pos.each do |url, pos_list|
      title_scores[url] = 0
      @query.each do |index|
        title_scores[url] += index_to_url[index][url][0]
      end
    end

    # calculate count_score
    count_score = {}
    url_to_pos.each do |url, pos_list|
      count_score[url] = 0
      @query.each do |index|
        count_score[url] += index_to_url[index][url][1].length
      end
    end

    # calculate order_score
    order_score = {}
    url_to_pos.each do |url, pos_list|
      order_score[url] = 0
      pos_list.each_with_index do |w1, w1_i|
        w1.each do |w1_pos|
          offset = 1
          f = true
          pos_list[w1_i+1..-1].each do |w2|
            f &&= w2.include? (w1_pos + offset)
            break if !f
            order_score[url] += offset + 1 if f
            offset += 1
          end
        end
      end
    end

    # Priority Queue of Document type
    doc_pq = PQueue.new() { |a,b| a.total > b.total }
    order_score.each do |url, score|
      doc_pq.push Document.new(url, score, title_scores[url], count_score[url])
    end

    results = []
    (0..MAX_RESULT_NUMBER).each do
      results << doc_pq.pop
    end

    results
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
