# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects do
  resources :recurring_tasks, except: [:show]
end
