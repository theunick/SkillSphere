class AccountsController < ApplicationController
  before_action :set_account, only: %i[show edit update destroy become_seller become_customer]
  
  def index
    @account = current_user
    @assistance = Assistance.new
    @accounts = Account.all
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
  
  def destroy
    @account.destroy
    redirect_to accounts_url, notice: 'Account was successfully destroyed.'
  end

  def become_seller
    @account = Account.find(params[:id])
    @account.role ||= 'seller'
    redirect_to accounts_path(@account), notice: 'Role updated to seller.'
  end
  
    
  def become_customer
    @account = Account.find(params[:id])
    @account.role ||= 'customer'
    redirect_to accounts_path(@account), notice: 'Role updated to customer.'
  end
  
  private
  
  def set_account
    @account = Account.find(params[:id])
  end
  
  def account_params
    params.require(:account).permit(:email, :name, :surname, :role)
  end

  def assistance
    @assistance = Assistance.new
  end
  
  def create_assistance
    @assistance = current_user.assistances.build(assistance_params)
    if @assistance.save
      redirect_to account_path, notice: 'Assistance request submitted successfully.'
    else
      render :index
    end
  end
  
  private
  
  def assistance_params
    params.require(:assistance).permit(:message)
  end  
end  