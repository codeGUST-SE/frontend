require "google/cloud/datastore"

class Search
  
  @index_kind = 'index_dev'

  # Google::Cloud::Datastore::Dataset for the configured dataset
  @@datastore ||= Google::Cloud::Datastore.new(
    project_id: Rails.application.config.
                      database_configuration[Rails.env]["dataset_id"]
  )

  def self.query(query)
    # get the current entity if it exists
    entity_key = @@datastore.key @index_kind, query
    entity = @@datastore.find(entity_key)
    result_hash = entity == nil ? {} : eval(entity['value'])
    result_hash.keys
  end

end
