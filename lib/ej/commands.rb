#!/usr/bin/env ruby
# coding: utf-8
require 'thor'
require 'yajl'
require 'elasticsearch'
require 'ej/core'
require 'active_support/core_ext/array'
require 'active_support/core_ext/string'
require 'logger'

USER_SETTING_FILE = "#{ENV['HOME']}/.ejrc"
CURRENT_SETTING_FILE = ".ejrc"

module Ej
  class Commands < Thor
    class_option :index, aliases: '-i', type: :string, default: '_all', desc: 'index'
    class_option :host, aliases: '-h', type: :string, default: 'localhost', desc: 'host'
    class_option :profile, aliases: '-p', type: :string, default: 'default', desc: 'profile by .ejrc'
    class_option :debug, aliases: '-d', type: :string, default: false, desc: 'debug mode'
    map '-s' => :search
    map '-c' => :facet
    map '-I' => :bulk
    map '-l' => :indices
    map '-a' => :aliases
    map '-m' => :mapping
    map '-e' => :debug_eval
    map '--j2h' => :json_to_hash
    map '--health' => :health

    def initialize(args = [], options = {}, config = {})
      super(args, options, config)
      @global_options = config[:shell].base.options
      @core = Ej::Core.new(@global_options['host'], @global_options['index'], @global_options['debug'])
    end

    desc 'init', 'init'
    def init
      setting_file_path = "#{ENV['HOME']}/.ejrc"
      default = {}
      default['default'] = {}
      default['default']['host'] = ask("What is default host?", default: 'localhost')
      default['default']['port'] = ask("What is default port?", default: 9200)
      default['default']['index'] = ask("What is default index?", default: '_all')
      File.write(setting_file_path, default.to_yaml)
      say("save setting file #{setting_file_path}", :green)
    end

    desc '-s [lucene query]', 'search'
    option :type, type: :string, aliases: '-t', default: nil, desc: 'type'
    option :size, type: :numeric, aliases: '-n', default: 10, desc: 'size'
    option :from, type: :numeric, aliases: '--from', default: 0, desc: 'from'
    option :source_only, type: :boolean, aliases: '--so', default: true, desc: 'from'
    def search(query = nil)
      puts_json(@core.search(options['type'], query, options['size'], options['from'], options['source_only']))
    end

    desc 'move', 'move index'
    option :source, type: :string, aliases: '--source', required: true, desc: 'source host'
    option :dest, type: :string, aliases: '--dest', required: true, desc: 'dest host'
    option :query, type: :string, aliases: '-q', default: nil, desc: 'query'
    def move
      @core.move(options['source'], options['dest'], options['query'])
    end

    desc 'dump', 'move index'
    option :query, type: :string, aliases: '-q', default: nil, desc: 'query'
    def dump
      @core.dump(options['query'])
    end

    desc '-c', 'facet'
    option :query, type: :string, aliases: '-q', default: '*', desc: 'query'
    option :size, type: :numeric, aliases: '-n', default: 10, desc: 'size'
    def facet(term)
      puts_json(@core.facet(term, options['size'], options['query']))
    end

    desc 'min', 'term'
    option :term, type: :string, aliases: '-k', desc: 'terms'
    def min
      puts_json(@core.min(options['term']))
    end

    desc 'max', 'count record, group by keys'
    option :term, type: :string, aliases: '-k', desc: 'terms'
    def max
      puts_json(@core.max(options['term']))
    end

    desc '-I', 'bulk import STDIN JSON'
    option :index, aliases: '-i', type: :string, default: "logstash-#{Time.now.strftime('%Y.%m.%d')}", required: true, desc: 'index'
    option :type, type: :string, aliases: '-t', default: nil, required: true, desc: 'type'
    option :timestamp_key, aliases: '--timestamp_key', type: :string, desc: 'timestamp key', default: nil
    option :add_timestamp, type: :boolean, default: true, desc: 'add_timestamp'
    option :id_keys, type: :array, aliases: '--id', default: nil, desc: 'id'
    def bulk
      @core.bulk(options['timestamp_key'], options['type'], options['add_timestamp'], options['id_keys'], options['index'])
    end

    desc 'health', 'health'
    def health
      puts_json(@core.health)
    end

    desc '-a', 'list aliases'
    def aliases
      puts_json(@core.aliases)
    end

    desc 'state', 'health'
    def state
      puts_json(@core.state)
    end

    desc 'indices', 'indices'
    def indices
      puts_json(@core.indices)
    end

    desc 'count', 'count'
    def count
      puts_json(@core.count)
    end

    desc 'stats', 'count'
    def stats
      puts_json(@core.stats)
    end

    desc 'mapping', 'count'
    def mapping
      puts_json(@core.mapping)
    end

    desc 'not_analyzed', 'not_analyzed'
    def not_analyzed
      json = File.read(File.expand_path('../../../template/not_analyze_template.json', __FILE__))
      hash = Yajl::Parser.parse(json)
      puts_json(@core.put_template('ej_init', hash))
    end

    desc 'put_routing', 'put routing'
    option :index, aliases: '-i', type: :string, default: nil, required: true, desc: 'index'
    option :type, aliases: '-t', type: :string, default: nil, required: true, desc: 'type'
    option :path, type: :string, default: nil, required: true, desc: 'path'
    def put_routing
      body = { options['type'] => {"_routing"=>{"required"=>true, "path"=>options['path']}}}
      puts_json(@core.put_mapping(options['index'], options['type'], body))
    end

    desc 'put_template', 'put_template'
    def put_template(name)
      hash = Yajl::Parser.parse(STDIN.read)
      puts_json(@core.put_template(name, hash))
    end

    desc 'create_aliases', 'create_aliases'
    option :alias, type: :string, aliases: '-a', default: nil, required: true, desc: 'type'
    option :indices, type: :array, aliases: '-x', default: nil, required: true, desc: 'type'
    def create_aliases
      @core.create_aliases(options['alias'], options['indices'])
    end

    desc 'recovery', 'recovery'
    def recovery
      @core.recovery
    end

    desc 'delete', 'delete index'
    option :index, aliases: '-i', type: :string, default: nil, required: true, desc: 'profile by .database.yml'
    option :query, type: :string, aliases: '-q', default: nil, desc: 'query'
    def delete
      @core.delete(options['index'], options['query'])
    end

    desc 'delete_template --name [name]', 'delete_template'
    option :name, type: :string, default: nil, required: true, desc: 'template name'
    def delete_template
      @core.delete_template(options['name'])
    end

    desc 'template', 'get template'
    def template
      puts_json(@core.template)
    end

    desc 'settings', 'get template'
    def settings
      puts_json(@core.settings)
    end

    desc 'warmer', 'get warmer'
    def warmer
      puts_json(@core.warmer)
    end

    desc 'refresh', 'get refresh'
    def refresh
      puts_json(@core.refresh)
    end

    desc '--j2h', 'json to hash'
    def json_to_hash
      pp Yajl::Parser.parse(STDIN.read)
    end

    private

    def puts_json(object)
      puts Yajl::Encoder.encode(object)
    end

    def setting
      if File.exist?(CURRENT_SETTING_FILE)
        return YAML.load_file(CURRENT_SETTING_FILE)
      end

      if File.exist?(USER_SETTING_FILE)
        return YAML.load_file(USER_SETTING_FILE)
      end
      return { host: 'localhost', index: '_all', port: 9200 }
    end
  end
end