require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::AssetsHelperTest < ActionView::TestCase
  include Ubiquo::AssetsHelper
  def test_shared_asset_warning_message_for_when_no_relation
    # No asset_relation
    a = assets(:image)
    
    assert_equal nil, shared_asset_warning_message_for( a, {
      :current_type => "ModelName",
      :current_id => nil
    })
  end
  
  def test_shared_asset_warning_message_for_when_its_the_same
    a = assets(:image)
    self.expects(:t).with(
      "ubiquo.media.affects_all_related_elements", :count => 1
    ).never
    
    prepare_asset_with shared_asset_options(:size => 1, :asset => a,:is_same_class => true)

    assert_equal nil, shared_asset_warning_message_for( a, {
      :current_type => shared_asset_options[:model_name],
      :current_id => shared_asset_options[:first_id]
    })
  end
  
  def test_shared_asset_warning_message_for_when_other_elements
    a = assets(:image)
    self.expects(:t).with(
      "ubiquo.media.affects_all_related_elements", :count => 1
    ).returns("warn!").once
    
    prepare_asset_with shared_asset_options(:size => 1, :asset => a)
    
    assert_equal "warn!", shared_asset_warning_message_for( a, {
      :current_type => shared_asset_options[:model_name],
      :current_id => 22
    })
  end

  def test_shared_asset_warning_message_for_when_other_elements_with_threshold
    set_ubiquo_media_config_to :advanced_edit_warn_user_when_changing_asset_in_use_threshold, 10 do
      a = assets(:image)
      prepare_asset_with shared_asset_options(:size => 9, :asset => a)

      assert_equal nil, shared_asset_warning_message_for( a, {
        :current_type => shared_asset_options[:model_name],
        :current_id => 22
      })
    end
  end
  
  def test_shared_asset_warning_message_for_when_other_elements_with_threshold_fires
    set_ubiquo_media_config_to :advanced_edit_warn_user_when_changing_asset_in_use_threshold, 10 do
      self.expects(:t).with(
        "ubiquo.media.affects_all_related_elements", :count => 33
      ).returns("warn!").once    
      a = assets(:image)
      prepare_asset_with shared_asset_options(:size => 33, :asset => a)

      assert_equal "warn!", shared_asset_warning_message_for( a, {
        :current_type => shared_asset_options[:model_name],
        :current_id => 22
      })
    end
  end
  
  # Prepares mocks scenario with asset_relations. Expects #shared_asset_options as options
  def prepare_asset_with options
    asset = options[:asset]
    ar = mock("")
    related_object = mock("")
    asset_relation = mock("")
    asset.stubs(:asset_relations).returns(ar)
    ar.expects(:count).returns(options[:size]).at_least_once
    ar.stubs(:first).returns(asset_relation)
    asset_relation.stubs(:related_object).returns(related_object)
    related_object.stubs(
        :is_a? => options[:is_same_class], # This makes the trick saying that the classes are not the same.
        :id => 22
    )
  end
  
  def shared_asset_options options = {}
    options.reverse_merge( 
      { 
        :asset => assets(:image),
        :size=> 1,
        :first_id => 22,
        :is_same_class => false,
        :model_name => "UbiquoUser"
      }
    )
  end
  
  # Wrapper to set the config to a value and restore it to not affect other tests
  def set_ubiquo_media_config_to key, value
    old = Ubiquo::Config.context(:ubiquo_media).get(key)
    Ubiquo::Config.context(:ubiquo_media).set(key, value)
    yield
  ensure
    Ubiquo::Config.context(:ubiquo_media).set(key, old)
  end

end