class CoursesController < ApplicationController
  impressionist actions: [:show, :show_customer]

  before_action :set_course, only: %i[show edit update destroy]

  def index
    @courses = Course.all

    if params[:search].present?
      @courses = @courses.where('title LIKE ?', "%#{params[:search]}%")
    end

    if params[:category].present?
      @courses = @courses.where(category: params[:category])
    end

    if params[:min_price].present?
      @courses = @courses.where('price >= ?', params[:min_price])
    end

    if params[:max_price].present?
      @courses = @courses.where('price <= ?', params[:max_price])
    end
  end

  def show
    if @course.hidden?
      redirect_to courses_path, alert: 'Questo corso non è disponibile.'
    end
    @report = Report.new
  end

  def new
    @course = Course.new
  end

  def edit
  end

  def create
    @course = Course.new(course_params)
    @course.seller = current_seller
    if @course.save
      redirect_to @course, notice: 'Course was successfully created.'
    else
      Rails.logger.error "Course creation failed: #{@course.errors.full_messages.join(", ")}"
      Rails.logger.error "Course attributes: #{@course.attributes.inspect}"
      Rails.logger.error "Params: #{course_params.inspect}"
      render :new
    end
  end

  def update
    if @course.update(course_params)
      redirect_to @course, notice: 'Course was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @course.update(hidden: true)
    redirect_to courses_url, notice: 'Course was successfully destroyed.'
  end

  def uploaded
    @courses = current_seller.courses
  end

  def purchase
    @course = Course.find(params[:id])
    @purchase = current_user.purchases.build(course: @course)
  
    if @purchase.save
      redirect_to bought_courses_path, notice: 'Course was successfully purchased.'
    else
      redirect_to course_path(@course), alert: "There was a problem with your purchase: #{@purchase.errors.full_messages.join(', ')}"
    end
  end

  def show_customer
    @course = Course.find(params[:id])
    @report = Report.new
  end

  private

  def set_course
    @course = Course.find(params[:id])
    impressionist(@course)
  end

  def course_params
    params.require(:course).permit(:title, :category, :description, :google_drive_file_ids, :price)
  end
end
