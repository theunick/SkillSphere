class AccountsController < ApplicationController
  before_action :set_account, only: %i[show edit update destroy new_assistance_request create_assistance_request]

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
  end

  def create
    @account = Account.new(account_params)
    if @account.save
      redirect_to @account, notice: 'Account was successfully created.'
    else
      render :new
    end
  end

  def update
    @account = Account.find(params[:id])
    if @account.role == 'customer'
      @account.update(role: 'seller')
      redirect_to accounts_path(@account), notice: 'Role updated to seller.'
    elsif @account.role == 'seller'
      @account.update(role: 'customer')
      redirect_to accounts_path(@account), notice: 'Role updated to customer.'
    end
  end

  def destroy
    @current = Account.find(params[:id])
    if @current.id == @account.id
      reset_session
    end
    @account.destroy
    reset_session
    redirect_to root_path, notice: 'Account deleted successfully.'
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

  private

  def assistance_request_params
    params.require(:assistance_request).permit(:description, :status)
  end

  private 

  def set_account
    if params[:id] =~ /\A\d+\z/
      @account = Account.find(params[:id])
    else
      redirect_to root_path, alert: "Account non valido."
    end
  end  

  def account_params
    params.require(:account).permit(:email, :name, :surname, :role)
  end
end
