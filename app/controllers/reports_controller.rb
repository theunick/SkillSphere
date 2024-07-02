class ReportsController < ApplicationController
  before_action :authenticate_admin!, only: [:index]

  def index
    Rails.logger.debug "Entering ReportsController#index"
    @reports = Report.includes(:course).all
  end

  def create
    @report = Report.new(report_params)
    @report.account = current_user
    if @report.save
      redirect_to course_path(@report.course_id), notice: 'Segnalazione inviata con successo.'
    else
      redirect_to course_path(@report.course_id), alert: 'Errore nell\'invio della segnalazione.'
    end
  end

  def destroy
    @report = Report.find(params[:id])
    @report.destroy
    redirect_to reported_courses_path, notice: 'Segnalazione eliminata con successo.'
  end

  private

  def report_params
    params.require(:report).permit(:course_id, :subject, :description)
  end

  def authenticate_admin!
    unless current_user && current_user.admin?
      redirect_to root_path, alert: 'Accesso non autorizzato.'
    end
  end
end
