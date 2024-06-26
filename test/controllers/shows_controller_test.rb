require "test_helper"

class ShowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @show = shows(:one)
  end

  test "should get index" do
    get shows_url
    assert_response :success
  end

  test "should get new" do
    get new_show_url
    assert_response :success
  end

  test "should create show" do
    assert_difference("Show.count") do
      post shows_url, params: { show: { cast: @show.cast, category: @show.category, description: @show.description, duration: @show.duration, end_date: @show.end_date, genre: @show.genre, imdb_rating: @show.imdb_rating, language: @show.language, name: @show.name, price: @show.price, release_date: @show.release_date, status: @show.status } }
    end

    assert_redirected_to show_url(Show.last)
  end

  test "should show show" do
    get show_url(@show)
    assert_response :success
  end

  test "should get edit" do
    get edit_show_url(@show)
    assert_response :success
  end

  test "should update show" do
    patch show_url(@show), params: { show: { cast: @show.cast, category: @show.category, description: @show.description, duration: @show.duration, end_date: @show.end_date, genre: @show.genre, imdb_rating: @show.imdb_rating, language: @show.language, name: @show.name, price: @show.price, start_date: @show.start_date, status: @show.status } }
    assert_redirected_to show_url(@show)
  end

  test "should destroy show" do
    assert_difference("Show.count", -1) do
      delete show_url(@show)
    end

    assert_redirected_to shows_url
  end
end
