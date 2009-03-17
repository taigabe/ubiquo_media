require File.dirname(__FILE__) + "/../test_helper.rb"

class TagTest < ActiveSupport::TestCase
  use_ubiquo_fixtures
  
  # Replace this with your real tests.
  def test_should_create_tag
    assert_difference "Tag.count" do
      tag = create_tag
      assert !tag.new_record?, "#{tag.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_name
    assert_no_difference "Tag.count" do
      tag = create_tag(:name => nil)
      assert tag.errors.on(:name)
    end
  end

  def test_should_urilize_name
    tag = create_tag
    tag.name = "á stràngé tag"
    tag.save
    assert_equal "astrangetag", tag.name 
  end

  def test_should_create_tags_for_string
    assert_difference "Tag.count", 3 do
      tags = Tag.create_for "first_tag, second_tag, third tag"
      assert tags.size == 3
    end
  end
  
  def test_should_create_tags_for_array
    assert_difference "Tag.count", 3 do
      tags = Tag.create_for ["first_tag", "second_tag", "third tag"]
      assert tags.size == 3
    end
  end

  def test_should_find_tag_with_name
    assert Tag.find_by(tags(:one).name)
  end

  def test_shouldnt_find_tag_with_name
    assert_nil Tag.find_by(tags(:one).name[0..-2]) # cuts last chars
  end

  def test_should_find_tag_with_id
    assert Tag.find_by(tags(:one).id) == tags(:one)
  end

  def test_shouldnt_find_tag_with_id
    assert_nil Tag.find_by(999)
  end

  private
  def create_tag(options = {})
    Tag.create({:name => "created_tag"}.merge!(options))
  end
end
