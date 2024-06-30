class ReportsController < ApplicationController
  before_action :set_report, only: [:show, :edit, :update, :destroy]
  
  def index
    @account = current_user
  end
  
  def show
  end
  
  def new
    @report = Report.new
  end
  
  def create
    @report = Report.new(report_params)
    if @report.save
      redirect_to @report, notice: 'Report was successfully created.'
    else
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @report.update(report_params)
      redirect_to @report, notice: 'Report was successfully updated.'
    else
      render :edit
    end
  end
  
  def destroy
    @report.destroy
    redirect_to reports_url, notice: 'Report was successfully destroyed.'
  end
  
  private
  
  def set_report
    @report = Report.find(params[:id])
  end
  
  def report_params
    params.require(:report).permit(:account_id, :course_id, :message)
  end
end
  