class ArticlesController < ApplicationController
  def new
    @article = Article.new
  end

  def create
    @article = Article.new(article_params)
    if @article.save
      redirect_to @article, notice: 'Article was successfully created.'
    else
      render :new
    end
  end

  def index
    @articles = Article.all
  end

  private

  def article_params
    params.require(:article).permit(:title, :content)
  end
end
