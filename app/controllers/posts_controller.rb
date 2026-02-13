class PostsController < ApplicationController
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]

  def index
    @posts = Post.order(created_at: :desc)
    @posts = @posts.where("title LIKE ?", "%#{search_params[:title]}%") if search_params[:title].present?
    @posts = @posts.where(status: search_params[:status]) if search_params[:status].present?
    @posts = @posts.where("created_at >= ?", search_params[:created_at_from]) if search_params[:created_at_from].present?
    @posts = @posts.where("created_at <= ?", "#{search_params[:created_at_to]} 23:59:59") if search_params[:created_at_to].present?

    respond_to do |format|
      format.html
      format.json { render json: @posts }
    end
  end

  def show
  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)
    if @post.save
      redirect_to posts_path, notice: "게시물이 작성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to post_path(@post), notice: "게시물이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "게시물이 삭제되었습니다."
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def search_params
    params.fetch(:q, {}).permit(:title, :status, :created_at_from, :created_at_to)
  end

  def post_params
    params.require(:post).permit(:title, :content)
  end
end
