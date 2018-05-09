class CurrentBlockQueue

  def initialize(tokens)
    @tokens = tokens
    @queue = []
    @count_hash = {}
    @smallest_window = []
  end

  def add(key, pos)
    @queue << Item.new(key, pos)

    if @count_hash.key? key
      @count_hash[key] += 1
    else
      @count_hash[key] = 1
    end

    # normalize
    while @count_hash[@queue[0].key] > 1
      @count_hash[@queue[0].key] -= 1
      @queue.shift
    end

    # compute current smallest window containing all tokens
    if @count_hash.length == @tokens.length  # if all tokens are in the queue
      min = @queue[0].pos
      max = @queue[@queue.length-1].pos
      @smallest_window = [min, max] if ((@smallest_window == []) || (max - min < @smallest_window[1] - @smallest_window[0]))
    end
  end

  def smallest_window
    @smallest_window
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
