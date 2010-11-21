require 'spec_helper'

describe Account do
  before(:each) do
    @account = Account.create!(Factory.attributes_for(:account))
  end
  
  it { should validate_presence_of(:time_zone).with_message(/must indicate preferred time zone/) }
  
  it { should validate_presence_of(:name).with_message(/must have a name/) }
  it { should validate_uniqueness_of(:name).with_message(/must be unique/) }
  it "should ensure name is subdomain-safe" do
    should allow_value("testpage").for(:name)
    should allow_value("test-page").for(:name)  
    should allow_value("testpage1").for(:name)

    should_not allow_value("testPage").for(:name)
    should_not allow_value("test_page").for(:name)
    should_not allow_value('test/page').for(:name)
    should_not allow_value("test page").for(:name)
    should_not allow_value("test$page").for(:name)
  end
  
  it { should have_many(:documents).dependent(:destroy) }
  it { should have_many(:articles) }
  it { should have_many(:email_templates).dependent(:destroy) }
  it { should have_many(:blogs).dependent(:destroy) }
  it { should have_many(:lists).dependent(:destroy) }
  it { should have_many(:pages).dependent(:destroy) }
    
  it { should have_many(:comments).dependent(:destroy) }
  
  it "should keep track of users invited to have access to the account" do
    should have_many(:user_invitations)
  end

  it "should know a human-readable list of its managers" do
    managers = (1..3).collect{ Factory(:user) }
    @account.managers_list.should == nil
    
    managers[0].has_role('manager', @account)
    @account.managers_list.should == "#{managers[0].name} <#{managers[0].email}>"
    
    managers[1].has_role('manager', @account)
    @account.managers_list.should == "#{managers[0].name} <#{managers[0].email}> and #{managers[1].name} <#{managers[1].email}>"
    
    
    managers[2].has_role('manager', @account)
    @account.managers_list.should == "#{managers[0].name} <#{managers[0].email}>, #{managers[1].name} <#{managers[1].email}> and #{managers[2].name} <#{managers[2].email}>"
  end
  
  it "should update convert its image settings from HTML-form friendly format into ImageMagick friendly format" do
    @account.image_settings = {"small"=>{:height=>"", :width=>"218"}, "medium"=>{:height=>"458", :width=>""}, "thumb"=>{:height=>"190", :width=>"100"}}
    @account.settings["image"]["small"].should ==  ["218>", "jpg"]
    @account.settings["image"]["medium"].should ==  ["x458>", "jpg"]
    @account.settings["image"]["thumb"].should ==  ["100x190>", "jpg"]
  end
  
  describe "#feed_settings=" do  
    it "should store feed settings in settings hash" do
      @account.feed_settings = {"limit" => 100, "full_text" => false}
      @account.settings["feed"]["limit"].should ==  100
      @account.settings["feed"]["full_text"].should ==  false
    end
  end
  
  describe "#feed_settings" do
    it "should make feed settings available as a simple struct" do
      @account.settings["feed"] = {"limit" => "100", "full_text" => "false"}
      
      @account.feed_settings.limit.should == 100
      @account.feed_settings.full_text.should be_false
    end
  end
  
  describe "role management" do
    before do
      @user = Factory(:user)
    end
  
    it "should promote user on account, if applicable" do
      @user.has_role?('staff', @account).should be_false
      
      @account.promote(@user)
      @user.has_role?('staff', @account).should be_true
      
      @account.promote(@user)      
      @user.has_role?('editor', @account).should be_true
      
      @account.promote(@user)      
      @user.has_role?('manager', @account).should be_true
      @user.has_role?('editor', @account).should be_false
      
      @user.has_role?('staff', @account).should be_true
    end
    
    it "should demote user on account, if applicable" do
      @user.has_role('staff', @account)
      @user.has_role('manager', @account)
      
      @account.demote(@user)
      @user.has_role?('editor', @account).should be_true
      @user.has_role?('manager', @account).should be_false
      
      @account.demote(@user)
      @user.has_role?('editor', @account).should be_false
      @user.has_role?('staff', @account).should be_true
      
      @account.demote(@user)
      @user.has_role?('staff', @account).should be_false
    end
  end

  describe "designs" do
    it { should have_many(:designs) }
  
    it "should keep track of which design is currently being shown to users" do
      @account.current_design.should be_nil
      @design = Factory(:design, :account => @account)
      @account.current_design = @design

      @account.current_design.should == @design
    end
  end
  
  it "should return formal name as display name, if provided" do
    @account.display_name.should == @account.name
    @account.update_attribute(:formal_name, "New formal name")
    @account.display_name.should == @account.formal_name
  end
  
  describe "network" do
    it { should have_many(:network_memberships).dependent(:destroy)  }
    it { should have_many(:network_members) }
    
    describe "membership" do
      it "should be know whether an account is in its network" do
        member_account = Factory(:account)
        @account.has_network_member?(member_account).should be_false
        
        membership = Factory(:membership, :account => member_account, :network_owner => @account)
        @account.has_network_member?(member_account).should be_true
      end
      
      it "should return network member ids" do
        membership1 = Factory(:membership, :network_owner => @account)
        membership2 = Factory(:membership, :network_owner => @account)
        
        @account.network_member_ids.should include(membership1.account.id)
        @account.network_member_ids.should include(membership2.account.id)
      end
    end
    
    describe "articles" do
       describe "making a copy" do
        context "as network owner" do
          before do
            @membership = Factory(:membership, :network_owner => @account)
          end

          it "should pick up article from network member" do
            article = Factory(:published_article, 
                              :title => "This is a test article",
                              :account => @membership.account )
            article.tag_list = "Tag 1, Tag 2"
            article.mediafiles = (1..2).collect{ Factory(:mediafile, :account => @membership.account)}
            article.mediafiles.each do |mediafile| 
              article.waxing_for(mediafile).update_attribute(:caption, "This caption is for #{mediafile.file.url(:original)}.")
            end

            network_copy = @membership.network_owner.make_network_copy(article)

            network_copy.should_not be_new_record
            network_copy.account.should == @account
            network_copy.section.should be_nil
            network_copy.status.should be_nil
            network_copy.published_at.should be_nil
            network_copy.authors_list.should == article.authors_list
            network_copy.mediafiles.length.should == article.mediafiles.length
            network_copy.waxings.first.caption.should == article.waxings.first.caption
            network_copy.account.should == @account
            network_copy.title.should == article.title
            network_copy.tag_list.should == article.tag_list
          end

          describe "authors" do
            it "should pick up article authors from network member" do
              authors = (1..3).collect{ Factory(:author, :account => @membership.account) }
              article = Factory(:published_article, 
                                :authors =>  authors,
                                :account => @membership.account )
                              
              network_copy = @membership.network_owner.make_network_copy(article)
              
              network_copy.authors.should_not eql(authors)
              network_copy.authors.each_with_index { |author, i| author.name.should eql(authors[i].name)   }
            end
            
            it "should not create duplicates, if authors with those names already exist" do
              source_authors = (1..3).collect{ Factory(:author, :account => @membership.account) }
              network_authors = source_authors.collect{ |author| Factory(:author, :name => author.name, :account => @membership.network_owner) }
              article = Factory(:published_article, 
                                :authors =>  source_authors,
                                :account => @membership.account )

              network_copy = @membership.network_owner.make_network_copy(article)
              
              network_copy.authors.should_not eql(source_authors)
              network_copy.authors.should eql(network_authors)
            end
          end

          it "should record user checking out, if provided" do
            user = Factory(:user)
            user.has_role("staff", @account)
            user.has_role("manager", @account)
            article = Factory(:published_article, 
                              :title => "This is a test article",
                              :account => @membership.account )

            network_copy = @account.make_network_copy(article, user)
            network_copy.checkout.user.should == user
          end

          it "should not pick up an out-of-network article" do
            article = Factory(:published_article, 
                               :title => "This is a test article")
            network_copy = @account.make_network_copy(article)
            network_copy.should be_nil
          end

          it "should not pick up draft article from network member" do
            article = Factory(:draft_article, 
                              :title => "This is a test article",
                              :account => @membership.account )
            network_copy = @account.make_network_copy(article)
            network_copy.should be_nil
          end

          it "should not pick up scheduled article from network member" do
            article = Factory(:scheduled_article, 
                              :title => "This is a test article",
                              :account => @membership.account )
            network_copy = @account.make_network_copy(article)
            network_copy.should be_nil
          end
        end
      end
      it "should know if it has a network copy of a given article" do
        article = Factory(:published_article)
        @account.should_not have_network_copy_of(article)
        
        membership = Factory(:membership, :account => article.account, :network_owner => @account)
        @account.make_network_copy(article)
        @account.should have_network_copy_of(article)
      end
      
      it "should find network copies of a given article" do
        article = Factory(:published_article)
        membership = Factory(:membership, :account => article.account, :network_owner => @account)
        @account.find_network_copy_of(article).should be_nil
        
        article_copy = @account.make_network_copy(article)
        @account.find_network_copy_of(article).should eql(article_copy)
      end
      
      it "should know if it is a network owner" do
        @account.should_not be_network_owner
        
        Factory(:membership, :network_owner => @account)
        
        @account.should be_network_owner
      end      
    end
  end
  
end