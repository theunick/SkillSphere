class AssistanceRequestsController < ApplicationController
  before_action :set_account, only: [:create, :destroy, :update]

  def index
    if current_user.admin?
      @assistance_requests = AssistanceRequest.visible
    else
      @assistance_requests = current_user.assistance_requests
    end
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
      respond_to do |format|
        format.html { redirect_to all_assistances_path, notice: 'Risposta inviata con successo.' }
        format.json { render json: { id: @assistance_request.id } }
      end
    else
      render :index, alert: 'Errore nell\'invio della risposta.'
    end
  end

  def destroy
    @assistance_request = AssistanceRequest.find_by(id: params[:id], account_id: @account.id)
    if @assistance_request
      @assistance_request.update(hidden: true)
      respond_to do |format|
        format.html {
          if current_user.admin?
            redirect_to all_assistances_path, notice: 'Richiesta di assistenza nascosta con successo.'
          else
            @assistance_request.destroy
            redirect_to accounts_path, notice: 'Richiesta di assistenza eliminata con successo.'
          end
        }
        format.json { render json: { id: @assistance_request.id, action: 'destroy' } }
      end
    else
      redirect_to accounts_path, alert: 'Richiesta di assistenza non trovata.'
    end
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def assistance_request_params
    params.require(:assistance_request).permit(:message, :status)
  end

  def response_params
    params.require(:assistance_request).permit(:response)
  end
end
