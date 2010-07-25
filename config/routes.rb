ActionController::Routing::Routes.draw do |map|
  
  map.root :controller => :public_front_pages, :action => :show
  map.public_front_page '/', :controller => :public_front_pages, :action => :show

  map.public_article '/articles/:id', :controller => :public_articles, :action => :show
  map.public_page '/pages/*id', :controller => :public_pages, :action => :show
  map.public_category '/categories/*id', :controller => :public_categories, :action => :show
  map.public_search '/search', :controller => :public_search, :action => :show
  map.public_issues '/issues', :controller => :public_issues, :action => :index
  map.public_issue '/issues/:id', :controller => :public_issues, :action => :show
  map.public_blogs '/blogs', :controller => :public_blogs, :action => :index
  map.public_blog '/blogs/:id', :controller => :public_blogs, :action => :show
  map.public_blog_entry '/blogs/:blog_slug/:id', :controller => :public_entries, :action => :show

  map.front_page_preview '/front_page/preview', :controller => :public_front_pages, :action => :preview 
  
  # Admin routes
  map.with_options(:path_prefix => "/admin") do |admin|
    admin.resources :account_invitations, :only => [:create, :edit, :update, :destroy]

    admin.resources :password_resets
    admin.resources :users, :member => { :promote => :put, :demote => :put, :deputize => :put, :letgo => :delete }

    admin.resources :accounts
    
    admin.current_design '/current_design', :controller => :designs, :action => :current_design
    
    admin.resources :invitations, :only => [:new, :create, :edit, :update, :destroy]
    admin.resources :user_invitations, :only => [:create, :edit, :update, :destroy]
  
    admin.resource :front_page, :only => [:edit, :update]
  
    admin.resources :designs do |design|
      design.resources :templates
      design.resources :template_files
    end
  
    admin.resources :documents do |document|
      document.resources :mediafiles
      document.resources :waxings
    end
  
    admin.resources :articles, :collection => { :search => :get } do |article|
      article.resources :mediafiles
      article.resources :authors
      article.resources :tags
      article.resources :waxings
      article.resources :printings
    end
  
    admin.resources :mediafiles do |mediafile|
      mediafile.resources :authors
      mediafile.resources :tags
    end
    
    admin.resources :blogs, :member => { :manage_contributors => :get, :add_contributor => :put, :remove_contributor => :put, :promote_contributor => :put, :demote_contributor => :put } do |blog|
      blog.resources :entries do |entry|
        entry.resources :mediafiles
        entry.resources :waxings
        entry.resources :tags
      end
    end
    
    admin.resources :entries, :only => [:new, :edit, :update, :destroy] do |entry|
      entry.resources :mediafiles
      entry.resources :waxings
      entry.resources :tags
    end
    
    admin.resources :lists, :except => :show
    admin.resources :pages
    admin.resources :issues, :member => { :upload_pdf => :post } 
    admin.resources :authors
    admin.resources :categories, :member => { :deactivate => :put, :reactivate => :put }
    admin.resources :waxings
    admin.resources :actions
    
    admin.resource :search
    admin.resource :dashboard
    
    admin.resource :network, :member => { :checkout_article => :post } do |network|
      network.show_article '/articles/:id', :controller => :networks, :action => :show_article, :conditions => { :method => :get }
      network.show_members '/members', :controller => :networks, :action => :show_members, :conditions => { :method => :get }
      network.update_members '/members', :controller => :networks, :action => :update_members, :conditions => { :method => :post }
    end
  end 
   
end
