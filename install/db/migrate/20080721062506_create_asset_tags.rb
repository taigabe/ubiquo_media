class CreateAssetTags < ActiveRecord::Migration
  def self.up
    create_table :asset_tags do |t|
      t.integer :asset_id
      t.integer :tag_id

      t.timestamps
    end
  end

  def self.down
    drop_table :asset_tags
  end
end
