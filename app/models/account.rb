class Account < ApplicationRecord
    enum role: { customer: 0, seller: 1, admin: 2 }
  
    validates :email, presence: true, uniqueness: true
    validates :name, presence: true
    validates :surname, presence: true
    validates :role, presence: true, inclusion: { in: roles.keys }
end