class CurrentBlockQueue

  def initialize(tokens)
    @tokens = tokens
    @queue = []
    @all_tokens = false
    @count_hash = Hash[@tokens.collect {|token| [token, 0]}]
    @token_set = Set[]
    @best_window = []
  end

  def add(key, pos)
    @queue << Item.new(key, pos)
    @count_hash[key] += 1
    @token_set.add(key)
    puts "#{@queue}"
    self.normalize
    puts "After norm: #{@queue}"

    @all_tokens = @token_set.length == @tokens.length

    if @all_tokens
      puts "all tokens"
      min = @queue[0].pos
      max = @queue[@queue.length-1].pos
      @best_window = [min, max] if @best_window == [] || max - min < @best_window[1] - @best_window[0]
    end

    puts "#{@tokens}"
    puts "#{@token_set.length}"
  end

  def best_window
    @best_window
  end

  def normalize
    while @count_hash[@queue[0].key] > 1
      @count_hash[@queue[0].key] -= 1
      @queue.shift
    end
  end

  class Item

    def initialize(key, pos)
      @key = key
      @pos = pos
    end

    def key
      @key
    end

    def pos
      @pos
    end

  end

end
