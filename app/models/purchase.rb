class Purchase < ApplicationRecord
  belongs_to :account
  belongs_to :course
end
