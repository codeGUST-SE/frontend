
module DocumentRetrieval

  INDEX_KIND = 'index'
  @@cache = ActiveSupport::Cache::MemoryStore.new

  def self.get_cache
    @@cache
  end

  def self.get_index_kind
    INDEX_KIND
  end

end
