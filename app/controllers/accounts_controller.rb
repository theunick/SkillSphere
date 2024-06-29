class AccountsController < ApplicationController
  before_action :set_account, only: %i[show edit update destroy]
  
  def index
    @account = current_user
    @assistance = Assistance.new
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
  
  def become_seller
    if @account.update(role: 1)
      redirect_to accounts_path, notice: 'Account has been updated to seller.'
    else
      redirect_to accounts_path, alert: 'Failed to update account.'
    end
  end
  
  def destroy
    @account.destroy
    redirect_to accounts_url, notice: 'Account was successfully destroyed.'
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

  def become_customer
    if @account.update(role: 0)
      redirect_to accounts_path, notice: 'Account has been updated to customer.'
    else
      redirect_to accounts_path, alert: 'Failed to update account.'
    end
  end
    
  def become_seller
    if @account.update(role: 1)
      redirect_to accounts_path, notice: 'Account has been updated to seller.'
    else
      redirect_to accounts_path, alert: 'Failed to update account.'
    end
  end

  def become_admin
    if @account.update(role: 2)
      redirect_to accounts_path, notice: 'Account has been updated to admin.'
    else
      redirect_to accounts_path, alert: 'Failed to update account.'
    end
  end
end  