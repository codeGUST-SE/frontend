require 'fast_stemmer'
require 'google/cloud/datastore'

class Ranker

  def initialize(datastore, user_query)
    @datastore = datastore
    @query = simplify_query(user_query)
  end

  def query
    results, init_index = get_result_hash

    filtered_results = []
    results[init_index].each do |url, value|
      f = true
      @query.each do |index|
        f &&= results[index].key? url
      end
      filtered_results << url if f
    end
    filtered_results
  end

  private

  def get_result_hash
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
