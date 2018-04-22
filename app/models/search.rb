require "google/cloud/datastore"

class Search

  # Google::Cloud::Datastore::Dataset for the configured dataset
  @@datastore ||= Google::Cloud::Datastore.new(
    project_id: Rails.application.config.
                      database_configuration[Rails.env]["dataset_id"]
  )

  def self.query(user_query)
    Ranker.new(@@datastore, user_query).query
  end

end
