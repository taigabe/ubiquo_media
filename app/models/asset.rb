# An asset is a resource with name, description and one associated
# file.
class Asset < ActiveRecord::Base
  belongs_to :asset_type

  validates_presence_of :name, :asset_type_id, :type

  # Generic find (ID, key or record)
  def self.gfind(something, options={})
    case something
    when Fixnum
      find_by_id(something, options)
    when String, Symbol
      find_by_name(something.to_s, options)
    when Asset
      something
    else
      nil
    end
  end

  # filters:

  #   :type: ID of AssetType separated by commas
  #   :text: String to search in asset name and description
  #
  # options: find_options
  def self.filtered_search(filters = {}, options = {})
    filter_type = if filters[:type]
      types_id = filters[:type].to_s.split(",").map(&:to_i)
      {:find => {:conditions => ["assets.asset_type_id IN (?)", types_id]}}
    else {}
    end
    filter_text = unless filters[:text].blank?
      args = ["%#{filters[:text]}%"] * 2
      condition = "assets.name ILIKE ? OR assets.description ILIKE ?"
      {:find => {:conditions => [condition] + args}}
    else {}
    end
    filter_visibility = unless filters[:visibility].blank?
      {:find => {:conditions => ["assets.type = ?", "asset_#{filters[:visibility]}".classify]}}
    else {}
    end
    filter_create_start = if filters[:created_start]
      {:find => {:conditions => ["assets.created_at >= ?", filters[:created_start]]}}
    else {}
    end      
    filter_create_end = if filters[:created_end]
      {:find => {:conditions => ["assets.created_at <= ?", filters[:created_end]]}}
    else {}
    end      
    
    with_scope(filter_text) do
      with_scope(filter_type) do
        with_scope(filter_visibility) do
          with_scope(filter_create_start) do
            with_scope(filter_create_end) do  
              with_scope(:find => options) do
                Asset.find(:all)
              end
            end
          end
        end
      end
    end
  end
end
