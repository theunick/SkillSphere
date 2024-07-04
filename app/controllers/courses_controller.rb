class CoursesController < ApplicationController

  impressionist actions: [:show, :show_customer]
  
  before_action :set_course, only: %i[ show edit update destroy ]

  # GET /courses or /courses.json
  def index
    @courses = Course.where(hidden: false)
  end

  # GET /courses/1 or /courses/1.json
  def show
    if @course.hidden?
      redirect_to courses_path, alert: 'Questo corso non è disponibile.'
    end
    @report = Report.new
  end

  # GET /courses/new
  def new
    @course = Course.new
  end

  # GET /courses/1/edit
  def edit
  end

  # POST /courses or /courses.json
  def create
    @course = Course.new(course_params)
    @course.seller = current_seller
    if @course.save
      redirect_to @course, notice: 'Course was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /courses/1 or /courses/1.json
  def update
    if @course.update(course_params)
      redirect_to @course, notice: 'Course was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /courses/1 or /courses/1.json
  def destroy
    @course.update(hidden: true)
    redirect_to courses_url, notice: 'Course was successfully destroyed.'
  end

    # GET /courses/uploaded
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
    impressionist(@course)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_course
    @course = Course.find(params[:id])
    impressionist(@course)
  end

  

  # Only allow a list of trusted parameters through.
  def course_params
    params.require(:course).permit(:title, :code, :category, :description, :google_drive_file_ids, :price)
  end
end
