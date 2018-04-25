require 'pqueue'

class Ranker

  MAX_RESULT_NUMBER = 100

  def initialize(query)
    @query = query
  end

  def get_ranked_documents(url_to_index_to_pos, index_to_url)

    # calculate title_score
    title_scores = {}
    url_to_index_to_pos.each do |url, pos_list|
      title_scores[url] = 0
      @query.each do |index|
        title_scores[url] += index_to_url[index][url][0]
      end
    end

    # calculate count_score
    count_score = {}
    url_to_index_to_pos.each do |url, pos_list|
      count_score[url] = 0
      @query.each do |index|
        count_score[url] += index_to_url[index][url][1].length
      end
    end

    # calculate order_score
    order_score = {}
    url_to_index_to_pos.each do |url, pos_list|
      order_score[url] = 0
      pos_list.each_with_index do |w1, w1_i|
        w1.each do |w1_pos|
          offset = 1
          f = true
          pos_list[w1_i+1..-1].each do |w2|
            f &&= w2.include? (w1_pos + offset)
            break if !f
            order_score[url] += offset + 1 if f
            offset += 1
          end
        end
      end
    end

    # Priority Queue of Document type
    doc_pq = PQueue.new() { |a,b| a.total > b.total }
    order_score.each do |url, score|
      doc_pq.push Document.new(url, score, title_scores[url], count_score[url])
    end

    results = []
    (0..MAX_RESULT_NUMBER).each do
      break if doc_pq.top == nil
      results << doc_pq.pop
    end

    results
  end

end
