require "croque/version"
require "croque/aggregator"
require "croque/monsieur"
require 'rails'
require 'active_support'
require 'active_support/configurable'
require 'csv'

module Croque
  def self.configure(&block)
    yield @config ||= Croque::Configuration.new
  end

  def self.config
    @config
  end

  class Configuration
    include ActiveSupport::Configurable
    config_accessor :root_path, :log_dir_path, :store_path,
      :log_file_matcher, :hour_matcher, :matcher, :severity_matcher,
      :start_matcher, :end_matcher, :lower_time, :except_path_matcher
  end

  configure do |config|
    config.root_path = Pathname.new(Rails.root || Dir.pwd)
    config.log_dir_path = config.root_path.join('log')
    config.store_path = config.root_path.join('tmp', 'croque', Rails.env)
    config.log_file_matcher = /#{Rails.env}.log/
    config.hour_matcher = /dateThour/
    config.severity_matcher = /severity/
    config.matcher = /\[#{config.hour_matcher.source}:\d{2}:\d{2}\.\d+ #{config.severity_matcher.source}\]/
    config.start_matcher = /\-\- : Started/
    config.end_matcher = /\-\- : Completed/
    config.lower_time = 1000 # ms
    config.except_path_matcher = /\/assets\//
  end

  class << self
    def aggregate(date)
      Croque::Aggregator.aggregate(date)
    end

    def all
      # Get Aggregated List
      # return date list as Array
      Croque::Aggregator.all
    end

    def ranking(date, page: nil, per: nil)
      # Get ranking as Sorted Array
      # limit = 0 => all lines
      Croque::Monsieur.get_list(date, page, per)
    end

    def total_count(date)
      Croque::Monsieur.total_count(date)
    end
  end
end
