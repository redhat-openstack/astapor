#!/usr/bin/ruby
# From hostgroups and quickstack parameters yaml files:
# - get/set Foreman smart class parameters
# - get/set Foreman hostgroups
# - generates site.pp manifest from hostgroups
# Version 1.3
# Requires Foreman 1.6.0.15+

require 'rubygems'
require 'erb'
require 'foreman_api'
require 'logger'
require 'optparse'
require 'ostruct'
require 'yaml'

class Optparse
  def self.parse(args)
    options = OpenStruct.new
    options.base_url = 'https://127.0.0.1'
    options.debug = false
    options.hostgroups = '/usr/share/openstack-foreman-installer/config/hostgroups.yaml'
    options.params = '/usr/share/openstack-foreman-installer/config/quickstack.yaml.erb'
    options.password = 'changeme'
    options.username = 'admin'
    options.verbose = false

    opt_parser = OptionParser.new do |opts|
      opts.banner = <<-EOS
Usage: #{__FILE__} [OPTIONS] COMMAND
  COMMAND
    hostgroups
    parameters
    list_parameters
    nodes

  OPTIONS
      EOS

      opts.on('-b', '--url_base URL', 'Base URL') do |b|
        options.base_url = b
      end

      opts.on('-d', '--default_params FILE', 'File of Parameter defaults (YAML Template)') do |d|
        options.params = d
      end

      opts.on('-g', '--hostgroups FILE', 'File of Hostgroups defaults (YAML)') do |g|
        options.hostgroups = g
      end

      opts.on('-p', '--password NAME', 'password') do |p|
        options.password = p
      end

      opts.on('-u', '--username NAME', 'username') do |u|
        options.username = u
      end

      opts.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
        options.verbose = v
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end
    opt_parser.parse!(args)
    options
  end
end

class Configuration
  def initialize(filename)
    @data = YAML.load(File.open(filename))
  end

  def data
    @data
  end

  def to_s
    list=''
    @data.each { |k,v|  list << "#{k.to_s} => #{v.to_s}\n" }
    list
  end
end

class ConfigurationHostgroups < Configuration
end

class ConfigurationQuickstack < Configuration
  def initialize(filename)
    template = ERB.new(File.new(filename).read, nil, '%-')
    @data  = YAML.load(template.result(binding))
  end
end

class Foreman
  attr_reader :hostgroups, :hostgroupclasses, :puppetclasses, :smart_params

  def initialize(options, log)
    @log = log
    auth = {
      :logger   => options.debug ? log : nil,
      :base_url => options.base_url,
      :username => options.username,
      :password => options.password
    }

    @environment   = ForemanApi::Resources::Environment.new(auth)
    @hostgroups    = ForemanApi::Resources::Hostgroup.new(auth)
    @hostgroupclasses = ForemanApi::Resources::HostgroupClass.new(auth)
    @puppetclasses = ForemanApi::Resources::Puppetclass.new(auth)
    @smart_params  = ForemanApi::Resources::SmartClassParameter.new(auth)
  end

  def environment_id
    env = @environment.index({:search => 'production'})[0]['results'][0]
    return env['id'] if env
  end

  def hostgroup_create_update(name)
    hostgroup = @hostgroups.index({ :search => name })[0]['results']
    if hostgroup == []
      # Create Hostgroup
      data = {
        'name' => name,
        'environment_id' => environment_id
      }
      hostgroup = @hostgroups.create(data)[0]
      @log.info("Hostgroup: #{name} [CREATED]")
      hostgroup['id']
    else
      # Hostgroup exists
      hostgroup[0]['id']
    end
  end

  def key_type_get(value)
    # To Do - Fetch key_list via ForemanAPI when available?
    key_list = %w(string boolean integer real array hash yaml json)

    case value.class
    when Fixnum
      value_type = integer
    when Float
      value_type = real
    when FalseClass, TrueClass
      value_type = boolean
    else
      value_type = value.class.to_s.downcase
    end
    return value_type if key_list.include?(value_type)
  end

  def puppet_class_get(name)
    @puppetclasses.index({ :search => "name=#{name}" })[0]['results']
  end

  def puppet_classes_get(hg)
    list = []
    hg.pclassnames.each do |pclassname|
      puppetclass = puppet_class_get(pclassname)
      if puppetclass.has_key?('quickstack')
          puppetclass['quickstack'].each do |pclass|
          list << pclass['id']
        end
      else
        @log.warn("#{pclassname} puppetclass not in 'quickstack'")
      end
    end
    return list
  end
end

class Hostgroup
  include Enumerable

  attr_reader :name, :pclassnames

  def initialize(name, pclassnames)
    @name = name
    @pclassnames = pclassnames
  end

  def each
    @pclassnames.each do |puppet_class|
      yield name, puppet_class
    end
  end
end

class Hostgroups
  include Enumerable

  def initialize(list, foreman, log)
    @foreman = foreman
    @hostgroups = []
    @log = log
    list.each do |hg|
      pclassnames = hg[:class].kind_of?(Array) ? hg[:class] : [ hg[:class] ]
      @hostgroups << Hostgroup.new(hg[:name], pclassnames)
    end
  end

  def node_add(name, pclasses)
    title = name.gsub(' ', '-')
    title.gsub!(/\(|\)/, '')
    title.downcase!
    node = "node /#{title}/ {\n"

    pclasses.each do |pclass|
      node << "  include #{pclass}\n"
    end
    node << "}\n\n"
  end

  def each
    @hostgroups.each do |hostgroup|
      yield hostgroup
    end
  end

  def smart_params_each
    self.each do |hg|
      hg.each do |name, pclassname|
        puppetclass = @foreman.puppet_class_get(pclassname)
        if puppetclass.has_key?('quickstack')
          puppetclass['quickstack'].each do |pclass|
            res = @foreman.puppetclasses.show({ 'id' => pclass['id'] })[0]
            res['smart_class_parameters'].each do |param|
              yield name, pclass, param
            end
          end
        else
          @log.warn("#{pclassname}: puppetclass not in 'quickstack' [IGNORED]")
        end
      end
    end
  end

  def smart_class_params_get
    @log.info('Fetching Foreman smart class parameters for each puppet classes')
    smart_params_each do |hg, pclass, param|
      smart_param = @foreman.smart_params.show({ 'id' => param['id'] })[0]
      @log.info("'#{hg}' #{pclass['name']} #{smart_param['parameter']} => #{smart_param['default_value']}")
    end
  end

  def smart_class_params_set(params)
    @log.info('Pushing parameters to Foreman smart class parameters')
    smart_params_each do |hg, pclass, param|
      if params.include?(param['parameter'])
        default_value  = params.get(param['parameter'])
        parameter_type = @foreman.key_type_get(default_value)

        if parameter_type == 'array' && default_value.empty?
          default_value  = [].to_json
        end

        data = { 'id' => param['id'],
          'smart_class_parameter' => {
            'default_value'  => default_value,
            'parameter_type' => parameter_type,
            'override'       => true,
          }
        }
        @foreman.smart_params.update(data)
        @log.info("'#{hg}' #{pclass['name']} #{param['parameter']} [UPDATE]")
      end
    end
  end

  def to_foreman
    @log.info('Pushing Hostgroups to Foreman')
    self.each do |hg|
      id = @foreman.hostgroup_create_update(hg.name)
      @foreman.puppet_classes_get(hg).each do |pclass_id|
        hostgroupclasses = @foreman.hostgroupclasses.index({ 'hostgroup_id' => id, })[0]['results']
        if hostgroupclasses
          unless hostgroupclasses.include?(pclass_id)
            data = { 'hostgroup_id' => id, 'puppetclass_id' => pclass_id }
            @foreman.hostgroupclasses.create(data)
            @log.info("Hostgroup: #{hg.name}: puppetclass #{pclass_id} [ADDED]")
          end
        end
      end
    end
  end

  def to_nodes
    @log.info('Generating nodes manifests')
    nodes = "#Quickstack: nodes defintions generated from hostgroups\n"
    @hostgroups.each do |hg|
      nodes << node_add(hg.name, hg.pclassnames)
    end
    nodes
  end
end

class Parameter
  attr_reader :name, :value

  def initialize(name, value)
    @name = name
    @value = value[0]
  end

  def include?(name)
    return @name == name
  end
end

class Parameters
  attr_reader  :params

  def initialize(config, log)
    @params = []
    @log = log

    config.each do |param|
      @params << Parameter.new(param[0], param[1..-1])
    end
  end

  def include?(name)
    @params.each do |param|
      return true if param.include?(name)
    end
    return false
  end

  def get(name)
    @params.each do |param|
      return param.value if param.name == name
    end
  end
end

# Main
options = Optparse.parse(ARGV)

log = Logger.new(STDOUT)
log.datetime_format = "%d/%m/%Y %H:%M:%S"
log.level = options.verbose ? Logger::INFO : Logger::WARN

hostgroups = Hostgroups.new(ConfigurationHostgroups.new(options.hostgroups).data, Foreman.new(options, log), log)

case ARGV[0]

when 'list_parameters'
  params = Parameters.new(ConfigurationQuickstack.new(options.params).data, log)
  hostgroups.smart_class_params_get
when 'parameters'
  params = Parameters.new(ConfigurationQuickstack.new(options.params).data, log)
  hostgroups.smart_class_params_set(params)
when 'hostgroups'
  hostgroups.to_foreman
when 'nodes'
  puts hostgroups.to_nodes
else
  puts Optparse.parse(['-h'])
end
