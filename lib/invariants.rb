# frozen_string_literal: true

module Invariants
  class Configuration
    attr_accessor :default_error, :default_invariant_message

    def initialize
      @default_error = StandardError
      @default_invariant_message = "Invariant cannot be enforced: %{condition}"
    end
  end

  @global_configuration = Configuration.new

  class << self
    attr_accessor :global_configuration

    def configure
      yield(global_configuration)
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def invariants_configuration
      @invariants_configuration ||= Configuration.new
    end

    def configure_invariants
      yield(invariants_configuration)
    end

    def invariant(name, &block)
      (@invariants ||= {})[name] = { block: block }
    end

    def invariants
      @invariants
    end
  end

  private

  def enforce(condition, message, error)
    invariant = self.class.invariants[condition]
    raise ArgumentError, "Invariant not defined: #{condition}" unless invariant

    begin
      instance_exec(message, error, &invariant[:block])
    rescue => e
      raise error, message || e.message
    end
  end

  public

  def enforce_invariants(*conditions, &customizations_block)
    customizations = customizations_block ? customizations_block.call : {}

    conditions.each do |condition|
      options = customizations[condition]
      if options.nil?
        enforce(condition, nil, config.default_error)
      elsif options.is_a?(Hash)
        message = options[:msg] || config.default_invariant_message % { condition: condition }
        error = options[:e] || config.default_error
        enforce(condition, message, error)
      else
        raise ArgumentError, "Invalid options for #{condition}: #{options.inspect}"
      end
    end
  end

  private

  def config
    self.class.invariants_configuration
  end
end
