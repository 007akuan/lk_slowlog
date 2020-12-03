require 'test_helper'

class LkSlowlogControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get lk_slowlog_index_url
    assert_response :success
  end

end
