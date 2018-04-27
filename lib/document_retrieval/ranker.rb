require 'pqueue'

class Ranker

  MAX_RESULT_NUMBER = 100

  SUB_SCORE_2_DIST = 5
  SUB_SCORE_3_DIST = 8

  def initialize(query, docs)
    @query = query
    @docs = docs
  end

  def get_ranked_documents
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

  def calculate_order_scores
    @docs.get_docs.pmap do |url, doc|
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
  end

  def calculate_sub_scores
    @docs.get_docs.pmap do |url, doc|
      sub_score2 = 0
      @query.combination(2).each do |c|
        pos1_list = @docs.get_doc_tokens(url)[c[0]]
        pos2_list = @docs.get_doc_tokens(url)[c[1]]

        p1 = 0
        p2 = 0

        while true
          break if p1 == pos1_list.length || p2 == pos2_list.length

          min, max = [pos1_list[p1], pos2_list[p2]].minmax
          sub_score2 += 3 if (max - min).abs <= SUB_SCORE_2_DIST

          if pos1_list[p1] < pos2_list[p2]
            p1 += 1
          else
            p2 += 1
          end
        end
      end

      sub_score3 = 0
      @query.combination(3).each do |c|
        pos1_list = @docs.get_doc_tokens(url)[c[0]]
        pos2_list = @docs.get_doc_tokens(url)[c[1]]
        pos3_list = @docs.get_doc_tokens(url)[c[2]]

        p1 = 0
        p2 = 0
        p3 = 0

        while true
          break if p1 == pos1_list.length || p2 == pos2_list.length || p3 == pos3_list.length

          a = [pos1_list[p1], pos2_list[p2], pos3_list[p3]]
          min, max = a.minmax
          sub_score3 += 3 if (max - min).abs <= SUB_SCORE_3_DIST

          i = a.find_index(min)
          p1 += 1 if i == 0
          p2 += 1 if i == 1
          p3 += 1 if i == 2
        end
      end
      
      @docs.add_doc_sub_score(url, sub_score2 + sub_score3)
    end
  end

end
