require "test_helper"

class SellersControllerTest < ActionDispatch::IntegrationTest
  test "should get statistics" do
    get sellers_statistics_url
    assert_response :success
  end
end
