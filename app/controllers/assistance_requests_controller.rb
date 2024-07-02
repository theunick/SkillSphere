class AssistanceRequestsController < ApplicationController
  before_action :set_account, only: [:create, :destroy, :update]
  before_action :authenticate_admin!, only: [:index, :update]

  def index
    @assistance_requests = AssistanceRequest.includes(:account).all
  end

  def create
    @assistance_request = @account.assistance_requests.new(assistance_request_params)
    @assistance_request.account_id = current_user.id

    if @assistance_request.save
      redirect_to accounts_path, notice: 'Richiesta di assistenza inviata con successo.'
    else
      redirect_to accounts_path, alert: 'Errore nell\'invio della richiesta di assistenza.'
    end
  end

  def update
    @assistance_request = AssistanceRequest.find(params[:id])
    if @assistance_request.update(response_params)
      redirect_to all_assistances_path, notice: 'Risposta inviata con successo.'
    else
      render :index, alert: 'Errore nell\'invio della risposta.'
    end
  end

  def destroy
    @assistance_request = @account.assistance_requests.find(params[:id])
    @assistance_request.destroy
    redirect_to account_assistance_requests_path(@account), notice: 'Richiesta di assistenza eliminata con successo.'
  end

  private

  def assistance_request_params
    params.require(:assistance_request).permit(:message, :status)
  end

  def response_params
    params.require(:assistance_request).permit(:response)
  end

  def set_account
    @account = Account.find(params[:account_id])
  end

  def authenticate_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: 'Accesso non autorizzato.'
    end
  end
end
