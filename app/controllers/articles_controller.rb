class ArticlesController < ApplicationController
  def index
    @categories = ArticleCategory.where("articles_count > 0")
    page = params[:page].to_i
    page = 1 if page < 1
    if params[:category_id].blank?
      @articles = Article.page(page).per(3)
    else
      @category = ArticleCategory.find(params[:category_id])
      @articles = @category.articles.page(page).per(3)
    end
  end

  def show
    @article = Article.find(params[:id])
    @next_article = Article.where("created_at > ?", @article.created_at).first
    @prev_article = Article.where("created_at < ?", @article.created_at).first
  end

  def rightboat_mini
    pdf = File.join(Rails.root, 'public/pdfs/Rightboat.mini_06.1.pdf')
    send_file(pdf, filename: 'Rightboat.mini_06.1.pdf', disposition: 'inline', type: 'application/pdf')
  end
end