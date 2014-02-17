require 'erb'
require 'yaml'

class Configuration
  def initialize(filename)
    @options = YAML.load(File.open(filename))
  end

  def get
    @options
  end

  def to_s
    list=''
    @options.each { |k,v|  list << "#{k.to_s} => #{v.to_s}\n" }
    list
  end
end

class Hostgroups < Configuration
end

class Quickstack < Configuration
  def initialize(filename)
    template = ERB.new(File.new(filename).read, nil, '%-')
    @options  = YAML.load(template.result(binding))
  end
end

class Setup < Configuration
  def debug
    @options['debug']
  end

  def hostgroups
    @options['hostgroups']
  end

  def quickstack
    @options['quickstack']
  end

 def foreman_provisioning
    @options['foreman_provisioning']
  end

  def secondary_int
    @options['secondary_int']
  end
end
