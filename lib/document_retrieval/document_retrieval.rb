require 'google/cloud/datastore'

module DocumentRetrieval

  INDEX_KIND = 'index'
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

end
