require 'rubygems'
require 'test/unit'
require 'active_record'
require 'active_record/fixtures'

require 'ruby-debug'

begin
  require 'active_support/test_case'
rescue
end

require 'mongo_mapper'

MongoMapper.database = "acts_as_solr_reloaded-test"

RAILS_ROOT = File.dirname(__FILE__) unless defined? RAILS_ROOT
RAILS_ENV  = 'test' unless defined? RAILS_ENV
ENV["RAILS_ENV"] = "test"
ENV["ACTS_AS_SOLR_TEST"] = "true"

require File.expand_path(File.dirname(__FILE__) + '/../lib/acts_as_solr')
require File.expand_path(File.dirname(__FILE__) + '/../config/solr_environment.rb')

# Load Models
models_dir = File.join(File.dirname( __FILE__ ), 'models')
require "#{models_dir}/book.rb"
Dir[ models_dir + '/*.rb'].each { |m| require m }

if defined?(ActiveSupport::TestCase)
  class ActiveSupport::TestCase
    include ActiveRecord::TestFixtures
    self.fixture_path = File.dirname(__FILE__) + "/fixtures/"
  end unless ActiveSupport::TestCase.respond_to?(:fixture_path=)
else
  Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
end

class Test::Unit::TestCase
  def self.fixtures(*table_names)
    fixture_path = defined?(ActiveSupport::TestCase) ? ActiveSupport::TestCase.fixture_path : Test::Unit::TestCase.fixture_path
    if block_given?
      Fixtures.create_fixtures(fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(fixture_path, table_names)
    end
    table_names.each do |table_name|
      clear_from_solr(table_name)
      klass = instance_eval table_name.to_s.capitalize.singularize
      klass.find(:all).each{|content| content.solr_save}
    end
    
    clear_from_solr(:novels)
  end
  
  private
  def self.clear_from_solr(table_name)
    ActsAsSolr::Post.execute(Solr::Request::Delete.new(:query => "type_s:#{table_name.to_s.capitalize.singularize}"))
  end
end

class Rails
  def self.root
    RAILS_ROOT
  end

  def self.env
    RAILS_ENV
  end
end
