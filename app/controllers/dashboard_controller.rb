class DashboardController < ApplicationController
  def show
    @total_posts      = Post.count
    @posts_today      = Post.where(created_at: Time.current.beginning_of_day..).count
    @posts_this_week  = Post.where(created_at: Time.current.beginning_of_week..).count
    @posts_this_month = Post.where(created_at: Time.current.beginning_of_month..).count
    @recent_posts     = Post.order(created_at: :desc).limit(5)

    last_week_count   = Post.where(created_at: 1.week.ago.beginning_of_week...Time.current.beginning_of_week).count
    if last_week_count > 0
      @week_change_pct = ((@posts_this_week - last_week_count).to_f / last_week_count * 100).round(1)
    else
      @week_change_pct = nil
    end
  end
end
