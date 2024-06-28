# app/controllers/courses_controller.rb
require 'google/apis/drive_v3'
require 'google/api_client/client_secrets'

class CoursesController < ApplicationController
  before_action :set_course, only: %i[ show edit update destroy upload_file share_drive ]

  # GET /courses or /courses.json
  def index
    @courses = Course.all
  end

  # GET /courses/1 or /courses/1.json
  def show
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
    @course = current_seller.courses.build(course_params)
    if @course.save
      redirect_to @course, notice: 'Course was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /courses/1 or /courses/1.json
  def update
    @course.seller = current_seller
    if @course.update(course_params)
      redirect_to @course, notice: 'Course was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /courses/1 or /courses/1.json
  def destroy
    @course.destroy
    redirect_to courses_url, notice: 'Course was successfully destroyed.'
  end

  def upload_file
    if params[:file].present?
      drive_service = initialize_drive_service
      file_metadata = {
        name: params[:file].original_filename,
        parents: ['appDataFolder']
      }
      file = drive_service.create_file(file_metadata,
                                       fields: 'id',
                                       upload_source: params[:file].path,
                                       content_type: params[:file].content_type)

      @course.update(file_id: file.id)
      redirect_to @course, notice: 'File successfully uploaded to Google Drive.'
    else
      redirect_to @course, alert: 'No file selected.'
    end
  end

  def share_drive
    drive_service = initialize_drive_service
    @files = drive_service.list_files.files
  rescue Google::Apis::AuthorizationError
    redirect_to '/auth/google_oauth2'
  end

  private

  def initialize_drive_service
    client_secrets = Google::APIClient::ClientSecrets.load
    authorization = client_secrets.to_authorization
    authorization.update!(
      scope: 'https://www.googleapis.com/auth/drive',
      additional_parameters: {
        'access_type' => 'offline'
      }
    )
    authorization.refresh_token = session[:google_drive_credentials]['refresh_token']
    drive_service = Google::Apis::DriveV3::DriveService.new
    drive_service.authorization = authorization
    drive_service
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_course
    @course = Course.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def course_params
    params.require(:course).permit(:title, :code, :category, :description, :seller_id)
  end
end
