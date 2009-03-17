class CreateAssets < ActiveRecord::Migration
  def self.up
    create_table :assets do |t|
      t.string :name
      t.text :description
      t.integer :asset_type_id
      t.string :resource_file_name
      t.integer :resource_file_size
      t.string :resource_content_type
      t.string :type
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assets
  end
end
