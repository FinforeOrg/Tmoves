Streaming::Application.routes.draw do

  devise_for :members, :class_name => "Member" do
    get "/subscribe" => "devise/registrations#new"
  end

  devise_for :admin, :class_name => "User" do
    get "/login" => "devise/sessions#new"
    get "/logout" => "devise/sessions#destroy"
  end

  namespace :admin do
    resources :exports do
      collection do
        get 'autocomplete_keywords'
        get 'update_progress'
      end
      member do
        get 'resume_progress'
        get 'download'
      end
    end

    resources :keywords do
      collection do
        get 'save_orders'
      end
    end

    resources :keyword_categories do
      collection do
        get 'save_orders'
      end
    end
    resources :statistics do
      collection do
        get 'tracker'
        get 'keywords'
      end
    end

    resources :scanner_accounts do 
      collection do
        get 'auth'
        get 'callback'
      end
    end

    resources :tweet_users

    resources :tweet_results do
      collection do 
        get  'more_tweets'
        get  'total_records'
      end
    end

    resources :users


    resources :scanner_tasks do
     member do
      get 'restart'
     end
     collection do
      get 'more_workers'
      get 'export_track'
      get 'shutdown_worker'
     end
    end

   resources :chart_types

   resources :keyword_charts

  end
  
  resources :members do
	collection do
	  get 'unsubscribe'
	end
  end

  resource :home do
    collection do 
      get 'keywords'
      get 'info'
      get 'statistics'
      get 'more_tweets'
      get 'show_twitter'
      get 'average_statistic'
      get 'total_records'
      get 'follower_weight'
      get 'tickers'
      get 'prices_data'
      get 'keyword_indexes'
      get 'about_us'
      get 'term_of_service'
      get 'contact_us'
      get 'toc'
      post 'delivery_message'
	  get 'categories_tab'
    end
  end

  root :to => "home#keywords"

  match '/admin' => "admin/tweet_results#index", :as => :admin_root
  match '/' => "home#keywords"
  match '/info/:title/:keyword_id' => "home#info"
  match '/statistics/:title/:keyword_id' => "home#statistics"
  match '/more_tweets/:title/:keyword_id' => "home#more_tweets"
  match '/average_statistic/:title/:keyword_id' => "home#average_statistic"
  match '/follower_weight/:title/:keyword_id' => "home#follower_weight"
  match '/show_twitter/:id' => "home#show_twitter"
  match '/total_records' => "home#total_records"
  match '/keyword_indexes' => "home#keyword_indexes"
  match '/tickers/:title/:category_id' => "home#tickers"
  match '/prices_data/:title/:keyword_id' => "home#prices_data"
  match '/about_us' => "home#about_us"
  match '/categories_tab' => "home#categories_tab"
  match '/term_of_service' => "home#term_of_service"
  match '/contact_us' => "home#contact_us"
  match '/toc' => "home#toc"
  match '/delivery_message' => "home#delivery_message"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
#   root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
