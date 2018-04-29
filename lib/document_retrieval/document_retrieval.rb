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
    @@cache.fetch(index) if @@cache.exist?(index)
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

    urls = url_list.each_slice(200).to_a  # TODO determine best batch size
    urls.each do |sub_urls|
      key_list = []
      sub_urls.each do |url|
        key_list << @@datastore.key(PAGE_KIND, url)
      end
      entities = @@datastore.find_all(*key_list)

      # TODO handle possible exceptions
      # TODO handle nil
      entities.each do |entity|
        results[entity['page_url']] = {
          :title => entity['page_title'], :html => entity['page_html'],
          :score => entity['page_scores']}
      end
    end
    results
  end

end
