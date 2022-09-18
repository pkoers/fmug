class ArticlesController < ApplicationController
  def new
  end

  def create
  end

  def show
  end

  def index
    # grab all the articles for the index page
    @articles = Article.all
  end

  def destroy
  end
end
