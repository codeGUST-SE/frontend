require 'fast_stemmer'
require "google/cloud/datastore"

class Search

  INDEX_KIND = 'index'

  # Google::Cloud::Datastore::Dataset for the configured dataset
  @@datastore ||= Google::Cloud::Datastore.new(
    project_id: Rails.application.config.
                      database_configuration[Rails.env]["dataset_id"]
  )

  def self.query(user_query)
    query = simplify_query(user_query)

    results = {}
    min_index_size = 200000
    min_index = ''
    query.each do |index|
      retrieved = retrieve_index(index)
      results[index] = retrieved
      if min_index_size > retrieved.size
        min_index_size = retrieved.size
        min_index = index
      end
    end

    filtered_results = []
    init_index = min_index

    results[init_index].each do |url, value|
      f = true
      query.each do |index|
        f &&= results[index].key? url
      end
      filtered_results << url if f
    end
    filtered_results
  end

  private

  def self.retrieve_index(index)
    offset = 0
    result_hash = {}
    while true
      key = @@datastore.key(INDEX_KIND, "#{index}#{offset}")
      entity = @@datastore.find(key)
      break if entity == nil
      result_hash.merge!(eval(entity['value']))
      offset += 1
    end
    result_hash
  end

  def self.simplify_query(user_query)
    query = user_query.gsub(/[^a-z ]/i, ' ').split()
    simple_query = []
    query.each do |word|
      token = Stemmer::stem_word(word.downcase)
      simple_query << token if !simple_query.include? word
    end
    simple_query
  end

end
