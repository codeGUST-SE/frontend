require 'fast_stemmer'
require 'google/cloud/datastore'

class Ranker

  def initialize(datastore, user_query)
    @datastore = datastore
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

    # calculate scores
    scores = {}
    title_scores = {}
    url_to_pos.each do |url, pos_list|

      # calculate title scores
      title_scores[url] = 0
      @query.each do |index|
        title_scores[url] += index_to_url[index][url][0]
      end

      # calculate scores for consecutive query words
      scores[url] = 0
      pos_list.each_with_index do |w1, w1_i|
        w1.each do |w1_pos|
          offset = 1
          f = true
          pos_list[w1_i+1..-1].each do |w2|
            f &&= w2.include? (w1_pos + offset)
            break if !f
            scores[url] += offset + 1 if f
            offset += 1
          end
        end
      end
    end

    results = []
    scores.each do |url, score|
      results << Result.new(url, score, title_scores[url])
    end

    # TODO use a priority queue for more efficient sorting
    results.sort_by(&:total).reverse
  end

  class Result

    attr_accessor :score1, :title, :total, :url

    def initialize(url, score1, title)
      @url = url
      @score1 = score1
      @title = title
      @total = @score1 + @title
    end

  end

  private

  def get_index_to_url
    results = {}
    min_index_size = 200000
    min_index = ''
    @query.each do |index|
      retrieved = retrieve_index(index)
      results[index] = retrieved
      if min_index_size > retrieved.size
        min_index_size = retrieved.size
        min_index = index
      end
    end
    return results, min_index
  end

  def retrieve_index(index)
    DocumentRetrieval.get_cache.fetch(index) if DocumentRetrieval.get_cache.exist?(index)
    offset = 0
    result_hash = {}
    while true
      key = @datastore.key(DocumentRetrieval.get_index_kind, "#{index}#{offset}")
      entity = @datastore.find(key)
      break if entity == nil
      result_hash.merge!(eval(entity['value']))
      offset += 1
    end

    DocumentRetrieval.get_cache.write(index, result_hash, expires_in: 30.day)
    result_hash
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
