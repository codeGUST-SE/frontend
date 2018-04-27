require 'pqueue'

class Ranker

  MAX_RESULT_NUMBER = 100

  def initialize(query, docs)
    @query = query
    @docs = docs
  end

  def get_ranked_documents()

    # calculate order_score
    @docs.get_docs.each do |url, doc|
      order_score = 0
      @query.each_with_index do |token1, w1_i|
        w1 = @docs.get_doc_tokens(url)[token1]
        w1.each do |w1_pos|
          offset = 1
          f = true
          @query[w1_i+1..-1].each do |token2|
            w2 = @docs.get_doc_tokens(url)[token2]
            f &&= w2.include? (w1_pos + offset)
            break if !f
            order_score += offset + 1
            offset += 1
          end
        end
      end
      @docs.add_doc_order_score(url, order_score)
    end

    @docs.normalize_scores
    # Priority Queue of Document type
    doc_pq = PQueue.new() { |a,b| a.total > b.total }
    @docs.get_docs.each do |url, doc|
      doc_pq.push doc
    end

    results = []
    (0..MAX_RESULT_NUMBER).each do
      break if doc_pq.top == nil
      results << doc_pq.pop
    end

    results
  end

end
