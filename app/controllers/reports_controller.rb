class ReportsController < ApplicationController
  def index
    @monthly_counts = Post.group("strftime('%Y-%m', created_at)").count.sort.reverse
    @total_posts     = Post.count
  end
end
