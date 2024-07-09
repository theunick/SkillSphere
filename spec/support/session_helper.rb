# spec/support/session_helper.rb
module SessionHelper
    def log_in_as(user)
      page.set_rack_session(user_id: user.id)
    end
  end
  
  RSpec.configure do |config|
    config.include SessionHelper, type: :system
  end
  