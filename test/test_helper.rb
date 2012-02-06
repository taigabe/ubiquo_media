# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = "test.com"

Rails.backtrace_cleaner.remove_silencers!

# Run any available migration
ActiveRecord::Migrator.migrate File.expand_path("../../install/db/migrate/", __FILE__)

# Create a test file for tests
def test_file(contents = "contents", ext = "txt")
  Tempfile.new("test." + ext).tap do |file|
    file.write contents
    file.flush
  end
end

def sample_image
  File.open(File.join( File.dirname(__FILE__),
            "/fixtures/resources/sample.png"))
end

def mock_asset_params params = {}
  mock_params(params, Ubiquo::AssetsController)
end

def mock_assets_controller
  mock_controller Ubiquo::AssetsController
end

def mock_media_helper
  mock_helper(:ubiquo_media)
end

class AssetType # Using this model because is very simple and has no validations
  media_attachment :simple
  media_attachment :multiple, :size => :many
  media_attachment :sized, :size => 2
  media_attachment :all_types, :types => :ALL
  media_attachment :some_types, :types => %w{audio video}
end


if ActiveRecord::Base.connection.class.to_s == "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
  ActiveRecord::Base.connection.client_min_messages = "ERROR"
end

conn = ActiveRecord::Base.connection

conn.drop_table   :test_media_translatables rescue nil
conn.create_table :test_media_translatables, :translatable => true do |t|
  t.string :field1
  t.string :field2
end unless conn.tables.include?('test_media_translatable_model_with_relations')

conn.drop_table :test_media_translatable_models rescue nil
conn.create_table :test_media_translatable_models, :translatable => true do |t|
  t.string :field1
  t.string :field2
  t.integer :test_media_translatable_id
end unless conn.tables.include?('test_media_translatable_models')

class TestMediaTranslatable < ActiveRecord::Base
  translatable
  has_many :test_media_translatable_models
  accepts_nested_attributes_for :test_media_translatable_models
  share_translations_for :test_media_translatable_models
  validates_length_of :test_media_translatable_models, :minimum => 1
end

class TestMediaTranslatableModel < ActiveRecord::Base
  translatable
  belongs_to :test_media_translatable_model_with_relation
  media_attachment :sized,        :size => 2, :required => false
  media_attachment :sized_shared, :size => 2, :required => true, :translation_shared => true
end

