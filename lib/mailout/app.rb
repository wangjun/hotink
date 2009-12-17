require 'sinatra/base'

module Mailout 
  class App < Sinatra::Base
    include Authlogic::ControllerAdapters::SinatraAdapter::Adapter::Implementation

    set :views, File.dirname(__FILE__) + '/views'

    API_KEY = 'e03757750894d3afb19d93edf0bf9421-us1'
    
    def load_session 
        @account = Account.find(params[:id])
        halt 404 unless @account
        
        @current_user_session = UserSession.find
        @current_user = @current_user_session.nil? ? nil : @current_user_session.user 
        unless @current_user && (@current_user.has_role?("staff", @account) || @current_user.has_role?("admin"))
          redirect '/user_session/new'
        end
    end
    
    def initialize_mailchimp
      load_session
      @mailchimp = Hominid::Base.new({:api_key => API_KEY })
    end
    
    helpers do
      include ActionView::Helpers::TextHelper
    end

    get '/accounts/:id/mailouts' do
      initialize_mailchimp
      @campaigns = @mailchimp.campaigns
      erb :mailouts
    end
    
    post '/accounts/:id/mailouts' do
      initialize_mailchimp
      @mailchimp.create_campaign('regular', { :list_id => 'c18292dd69', :from_email => params[:mailout][:from_email], :from_name => params[:mailout][:name], :subject => params[:mailout][:subject], :to_email => params[:mailout][:to_email] }, { :html => "<h1>Test email</h1>" , :test =>"Test email" })
      redirect "/accounts/#{@account.id}/mailouts"
    end
    
    get '/accounts/:id/mailouts/new' do
      initialize_mailchimp
      erb :new_mailout
    end
    
    get '/accounts/:id/mailouts/:mailout' do
      initialize_mailchimp
      @campaign = @mailchimp.find_campaign_by_id(params[:mailout])
      erb :mailout
    end
    
    post '/accounts/:id/mailouts/:mailout/send' do
      begin
        initialize_mailchimp
        @campaign = @mailchimp.find_campaign_by_id(params[:mailout])
        @mailchimp.send(@campaign['id']) unless @campaign['emails_sent'].to_i > 0
      rescue
      ensure
        redirect "/accounts/#{@account.id}/mailouts"
      end
    end
  end
end