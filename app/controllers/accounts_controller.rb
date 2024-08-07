class AccountsController < ApplicationController
  before_action :set_account, only: %i[show edit update destroy new_assistance_request create_assistance_request make_customer make_seller make_admin]

  def index
    @account = current_user
    @accounts = Account.all
    @assistance_request = AssistanceRequest.new
  end

  def show
    @account = Account.find(params[:id])
  end  

  def new
    @account = Account.new
  end

  def edit
    @account = Account.find(params[:id])
  end

  def update
    @account = Account.find(params[:id])
    if @account.update(account_params)
      redirect_to root_path, notice: 'Bio aggiornata con successo.'
    else
      render :edit
    end
  end

  def create
    @account = Account.new(account_params)
    if @account.save
      redirect_to @account, notice: 'Account was successfully created.'
    else
      render :new
    end
  end

  def destroy
    if @account == current_user
      reset_session
      flash[:notice] = 'Your account has been deleted successfully.'
      if @account.destroy
        redirect_to root_path and return
      else
        redirect_to root_path, alert: 'There was an issue deleting your account.'
        return
      end
    else
      ActiveRecord::Base.transaction do
        @account.assistance_requests.destroy_all
        @account.courses.each do |course|
          course.reviews.destroy_all
          course.reports.destroy_all
        end
        @account.courses.destroy_all
        @account.reports.destroy_all
  
        if @account.destroy
          redirect_to admins_path, notice: 'Account deleted successfully.'
        else
          raise ActiveRecord::Rollback
        end
      end
    end
  rescue ActiveRecord::InvalidForeignKey => e
    redirect_to accounts_path, alert: "Failed to delete account: #{e.message}"
  end
  

  def new_assistance_request
    @account = Account.find(params[:id])
    @assistance_request = AssistanceRequest.new
  end

  def create_assistance_request
    @account = Account.find(params[:id])
    @assistance_request = @account.assistance_requests.build(assistance_request_params)
    if @assistance_request.save
      redirect_to account_path(@account), notice: 'Assistance request created successfully.'
    else
      render :new_assistance_request
    end
  end  

  def assistance_requests
    @assistance_requests = AssistanceRequest.all
  end

  def make_customer
    @account.update(role: 'customer')
    redirect_to accounts_path(@account), notice: 'Il ruolo è stato cambiato a customer.'
  end

  def make_seller
    @account.update(role: 'seller')
    redirect_to accounts_path(@account), notice: 'Il ruolo è stato cambiato a seller.'
  end

  def make_admin
    @account.update(role: 'admin')
    redirect_to admins_path, notice: 'L\'utente è stato promosso ad admin.'
  end

  def bought_courses
    @bought_courses = current_user.bought_courses
  end

  private

  def assistance_request_params
    params.require(:assistance_request).permit(:message, :status)
  end

  private 

  def set_account
    if params[:id] =~ /\A\d+\z/
      @account = Account.find(params[:id])
    else
      redirect_to root_path, alert: "Account non valido."
    end
  end  

  private

  def account_params
    params.require(:account).permit(:name, :email, :bio, :password, :password_confirmation)
  end
end
