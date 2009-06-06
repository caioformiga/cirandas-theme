require File.dirname(__FILE__) + '/../test_helper'
require 'memberships_controller'


# Re-raise errors caught by the controller.
class MembershipsController; def rescue_action(e) raise e end; end

class MembershipsControllerTest < Test::Unit::TestCase
  
  include ApplicationHelper

  def setup
    @controller = MembershipsController.new
    @request    = ActionController::TestRequest.new
    @request.stubs(:ssl?).returns(true)
    @response   = ActionController::TestResponse.new

    @profile = create_user('testuser').person
    login_as('testuser')
  end
  attr_reader :profile

  def test_local_files_reference
    assert_local_files_reference :get, :index, :profile => profile.identifier
  end
  
  def test_valid_xhtml
    assert_valid_xhtml
  end

  should 'list current memberships' do
    get :index, :profile => profile.identifier

    assert_kind_of Array, assigns(:memberships)
  end

  should 'present new community form' do
    get :new_community, :profile => profile.identifier
    assert_response :success
    assert_template 'new_community'
  end

  should 'be able to create a new community' do
    assert_difference Community, :count do
      post :new_community, :profile => profile.identifier, :community => { :name => 'My shiny new community', :description => 'This is a community devoted to anything interesting we find in the internet '}
      assert_response :redirect
      assert_redirected_to :action => 'index'

      assert Community.find_by_identifier('my-shiny-new-community').members.include?(profile), "Creator user should be added as member of the community just created"
    end
  end

  should 'be able to create a new community on wizard' do
    assert_difference Community, :count do
      post :new_community, :profile => profile.identifier, :community => { :name => 'My shiny new community', :description => 'This is a community devoted to anything interesting we find in the internet '}, :wizard => true
      assert_response :redirect
    assert_redirected_to :controller => 'search', :action => 'assets', :asset => 'communities', :wizard => true

      assert Community.find_by_identifier('my-shiny-new-community').members.include?(profile), "Creator user should be added as member of the community just created"
    end
  end

  should 'link to new community creation in index' do
    get :index, :profile => profile.identifier
    assert_tag :tag => 'a', :attributes => { :href => "/myprofile/#{profile.identifier}/memberships/new_community" }
  end

  should 'filter html from name' do
    login_as(profile.identifier)
    post :new_community, :profile => profile.identifier, :community => { :name => '<b>new</b> community' }
    assert_sanitized assigns(:community).name
  end

  should 'filter html from description' do
    login_as(profile.identifier)
    post :new_community, :profile => profile.identifier, :community => { :name => 'new community', :description => '<b>new</b> community' }
    assert_sanitized assigns(:community).description
  end

  should 'show number of members on list' do
    community = Community.create!(:name => 'my test community')
    community.add_member(profile)
    get :index, :profile => profile.identifier
    assert_tag :tag => 'li', :content => /Members: 1/
  end

  should 'show created at on list' do
    community = Community.create!(:name => 'my test community')
    community.add_member(profile)
    get :index, :profile => profile.identifier
    assert_tag :tag => 'li', :content => /Created at: #{show_date(community.created_at)}/
  end

  should 'show description on list' do
    community = Community.create!(:name => 'my test community', :description => 'description test')
    community.add_member(profile)
    get :index, :profile => profile.identifier
    assert_tag :tag => 'li', :content => /Description: description test/
  end

  should 'not show description to enterprises on list' do
    enterprise = Enterprise.create!(:identifier => 'enterprise-test', :name => 'my test enterprise')
    enterprise.add_member(profile)
    get :index, :profile => profile.identifier
    assert_no_tag :tag => 'li', :content => /Description:/
  end

  should 'show link to leave from community' do
    community = Community.create!(:name => 'my test community', :description => 'description test')
    community.add_member(profile)
    get :index, :profile => profile.identifier
    assert_tag :tag => 'a', :attributes => { :href => "/myprofile/#{profile.identifier}/memberships/leave/#{community.id}" }, :content => 'Leave'
  end

  should 'present confirmation before leaving a profile' do
    community = Community.create!(:name => 'my test community')
    community.add_member(profile)
    get :leave, :profile => profile.identifier, :id => community.id

    assert_response :success
    assert_template 'leave'
  end

  should 'actually leave profile' do
    community = Community.create!(:name => 'my test community')
    community.add_member(profile)
    assert_includes profile.memberships, community
    post :leave, :profile => profile.identifier, :id => community.id, :confirmation => '1'

    assert_response :redirect
    assert_redirected_to :action => 'index'

    profile = Profile.find(@profile.id)
    assert_not_includes profile.memberships, community
  end

  should 'leave profile when on wizard' do
    community = Community.create!(:name => 'my test community')
    community.add_member(profile)
    post :leave, :profile => profile.identifier, :id => community.id, :confirmation => '1', :wizard => true

    assert_response :redirect
    assert_redirected_to :controller => 'search', :action => 'assets', :asset => 'communities', :wizard => true

    profile = Profile.find(@profile.id)
    assert_not_includes profile.memberships, community
  end

  should 'current user is added as admin after create new community' do
    post :new_community, :profile => profile.identifier, :community => { :name => 'My shiny new community', :description => 'This is a community devoted to anything interesting we find in the internet '}
    assert_equal Profile::Roles.admin(profile.environment.id), profile.find_roles(Community.find_by_identifier('my-shiny-new-community')).first.role
  end

  should 'display button to create community' do
    get :index, :profile => 'testuser'
    assert_tag :tag => 'a', :attributes => { :href => "/myprofile/testuser/memberships/new_community" }
  end

  should 'render destroy_community template' do
    community = Community.create!(:name => 'A community to destroy')
    get :destroy_community, :profile => 'testuser', :id => community.id
    assert_template 'destroy_community'
  end

  should 'display destroy link only to communities' do
    community = Community.create!(:name => 'A community to destroy')
    enterprise = Enterprise.create!(:name => 'A enterprise test', :identifier => 'enterprise-test')

    person = Person['testuser']
    community.add_admin(person)
    enterprise.add_admin(person)

    get :index, :profile => 'testuser'

    assert_tag :tag => 'a', :attributes => { :href => "/myprofile/testuser/memberships/destroy_community/#{community.id}" }
    assert_no_tag :tag => 'a', :attributes => { :href => "/myprofile/testuser/memberships/destroy_community/#{enterprise.id}" }
  end

  should 'be able to destroy communities' do
    community = Community.create!(:name => 'A community to destroy')

    person = Person['testuser']
    community.add_admin(person)

    assert_difference Community, :count, -1 do
      post :destroy_community, :profile => 'testuser', :id => community.id
    end
  end

  should 'not display destroy link to normal members' do
    community = Community.create!(:name => 'A community to destroy')

    person = Person['testuser']
    community.add_member(person)

    login_as('testuser')
    get :index, :profile => 'testuser'

    assert_template 'index'
    assert_no_tag :tag => 'a', :attributes => { :href => "/myprofile/testuser/memberships/destroy_community/#{community.id}" }
  end

  should 'use the current environment for the template of user' do
    template = Community.create!(:identifier => 'test_template', :name => 'test@bli.com')
    template.boxes.destroy_all
    template.boxes << Box.new
    template.boxes[0].blocks << Block.new
    template.save!

    env = Environment.create!(:name => 'test_env')
    env.settings[:community_template_id] = template.id
    env.save!

    profile.environment = env
    profile.save!
    @controller.stubs(:environment).returns(env)

    post :new_community, :profile => profile.identifier, :community => { :name => 'test community', :description => 'a test community'}

    assert_equal 1, assigns(:community).boxes.size
    assert_equal 1, assigns(:community).boxes[0].blocks.size
  end

end
