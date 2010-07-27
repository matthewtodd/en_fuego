module EnFuego
  class Comments
    def initialize(comments)
      @comments = comments
    end

    def updated_at
      @comments.map { |comment| comment['created_at'] }.max
    end

    def to_html
      if @comments.any?
        "<h2>Comments</h2><ol>#{@comments.map { |c| comment_html(c) }}</ol>"
      else
        ''
      end
    end

    private

    def comment_html(comment)
      "<li><p>#{comment['user']['display_name']}: #{comment['body']}</p></li>"
    end
  end
end
