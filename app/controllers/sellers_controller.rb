class SellersController < ApplicationController
  def statistics
    @seller = Account.find(params[:id])
    @total_earnings = @seller.courses.joins(:purchases).sum('coalesce(courses.price, 0)')
    @courses_statistics = @seller.courses
                                 .left_joins(:purchases)
                                 .select('courses.*, COUNT(purchases.id) as purchases_count, SUM(coalesce(courses.price, 0)) as total_earnings')
                                 .left_joins(:impressions)
                                 .group('courses.id')
  end
end
