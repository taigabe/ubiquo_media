map.namespace :ubiquo do |ubiquo|
  ubiquo.resources :assets, :collection => {:search => :get}
end
