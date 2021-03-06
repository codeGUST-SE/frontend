require 'google/cloud/datastore'

module DocumentRetrieval

  INDEX_KIND = 'index'
  PAGE_KIND = 'page'

  @@cache = ActiveSupport::Cache::MemoryStore.new

  # Google::Cloud::Datastore::Dataset for the configured dataset
  @@datastore ||= Google::Cloud::Datastore.new(
    project_id: Rails.application.config.
                      database_configuration[Rails.env]["dataset_id"]
  )

  def self.retrieve_index(index)
    return @@cache.fetch(index) if @@cache.exist?(index)
    offset = 0
    result_hash = {}
    while true
      key = @@datastore.key(INDEX_KIND, "#{index}#{offset}")
      entity = @@datastore.find(key)
      break if entity == nil
      result_hash.merge!(eval(entity['value']))
      offset += 1
    end

    @@cache.write(index, result_hash, expires_in: 30.day)
    result_hash
  end

  def self.retrieve_pages(url_list)
    results = {}

    key_list = []
    url_list.each do |url|
      key_list << @@datastore.key(PAGE_KIND, url)
    end

    while key_list.length != 0
      entities = @@datastore.find_all(*key_list)
      # TODO handle possible exceptions
      # TODO handle nil
      entities.all do |entity|
        results[entity['page_url']] = {
          :title => entity['page_title'], :html => entity['page_html'],
          :score => entity['page_scores']}
      end
      key_list = entities.deferred
    end
    results
  end

end
