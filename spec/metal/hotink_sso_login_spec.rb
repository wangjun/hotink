require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class App < HotinkSso
  enable :sessions
end

describe HotinkSso do
  include Rack::Test::Methods    
  
  def app
    App
  end
  
  it "should display login form to unauthenticated user" do
    get '/sso/login'
    last_response.status.should == 401
    last_response.body.should include("Welcome to Hot Ink")
  end
  
  it "should allow users to log in using login" do
    user = Factory(:user, :password => "sesh_path", :password_confirmation => "sesh_path", :skip_session_maintenance => true)
    post '/sso/login', :login => user.login, :password => "sesh_path"
    last_response.status.should == 302
  end
  
  it "should allow users to log in using email address" do
    user = Factory(:user, :password => "sesh_path", :password_confirmation => "sesh_path", :skip_session_maintenance => true)
    post '/sso/login', :login => user.email, :password => "sesh_path"
    last_response.status.should == 302
  end
  
  it "should not login user without valid credentials" do
    user = Factory.attributes_for(:user)
    post '/sso/login', :login => user[:login], :password => user[:password]
    last_response.status.should == 401
  end
  
  it "should log out user" do
    user = Factory(:user, :password => "sesh_path", :password_confirmation => "sesh_path", :skip_session_maintenance => true)
    post '/sso/login', :login => user.login, :password => "sesh_path"
    
    get '/sso/login'
    last_response.status.should == 302 
    
    get '/sso/logout'
    get '/sso/login'
    last_response.status.should == 401
  end
  
end