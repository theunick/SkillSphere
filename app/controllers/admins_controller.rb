class AdminsController < ApplicationController
    def index
        @users = Account.all
    end

    def user_list
      @users = Account.all
    end
end
  