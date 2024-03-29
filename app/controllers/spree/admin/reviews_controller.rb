class Spree::Admin::ReviewsController < Spree::Admin::ResourceController
  helper Spree::ReviewsHelper

  def index
    @reviews = collection
  end

  def new
    @review = Spree::Review.new(product: @product)
    authorize! :create, @review
  end

  # save if all ok
  def create
    params[:review][:rating].sub!(/\s*[^0-9]*\z/, '') unless params[:review][:rating].blank?

    @review = Spree::Review.new(review_params)
    @review.product = @product
    @review.user = spree_current_user if spree_user_signed_in?
    @review.ip_address = request.remote_ip
    @review.locale = I18n.locale.to_s if Spree::Reviews::Config[:track_locale]

    authorize! :create, @review
    if @review.save
      @review.images.attach(params[:review][:images])
      flash[:notice] = Spree.t(:review_successfully_submitted)
      redirect_to spree.product_path(@product)
    else
      render :new
    end
  end


  def approve
    review = Spree::Review.find(params[:id])
    if review.update_attribute(:approved, true)
      flash[:notice] = Spree.t(:info_approve_review)
    else
      flash[:error] = Spree.t(:error_approve_review)
    end
    redirect_back fallback_location: admin_reviews_path
  end

  def edit
    return if @review.product
    flash[:error] = Spree.t(:error_no_product)
    redirect_back fallback_location: admin_reviews_path
  end

  private

  def collection
    params[:q] ||= {}
    @search = Spree::Review.ransack(params[:q])
    @collection = @search.result.includes([:product, :user, :feedback_reviews]).page(params[:page]).per(params[:per_page])
  end
end
