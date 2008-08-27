require 'test_helper'

class PatchUpdatesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:patch_updates)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_patch_update
    assert_difference('PatchUpdate.count') do
      post :create, :patch_update => { }
    end

    assert_redirected_to patch_update_path(assigns(:patch_update))
  end

  def test_should_show_patch_update
    get :show, :id => patch_updates(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => patch_updates(:one).id
    assert_response :success
  end

  def test_should_update_patch_update
    put :update, :id => patch_updates(:one).id, :patch_update => { }
    assert_redirected_to patch_update_path(assigns(:patch_update))
  end

  def test_should_destroy_patch_update
    assert_difference('PatchUpdate.count', -1) do
      delete :destroy, :id => patch_updates(:one).id
    end

    assert_redirected_to patch_updates_path
  end
end
