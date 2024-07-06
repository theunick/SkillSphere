class AdminsController < ApplicationController
  def index
    @role_filter = params[:role]
    if @role_filter.present?
      @accounts = Account.where(role: @role_filter)
    else
      @accounts = Account.all
    end
  end

  def user_list
    @accounts = Account.all
  end
end
