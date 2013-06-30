require 'ordinary/unit'
require 'set'

module Ordinary
  class Builder

    def initialize(&block)
      @context = Context.new(block)
    end

    # @attribute [r] context
    # @return [Ordinary::Builder::Context] the context of building
    attr_reader :context

    # Build units for a normalizer.
    #
    # @yield build units for a normalizer
    # @return [Ordinary::Unit, Ordinary::Units] units for a normalizer
    def build(&build)
      @context.instance_exec(&build)
    end

    module Context
      class << self
        attr_reader :current, :modules
      end

      def self.update(modules)
        @current = Class.new { include *[*modules, Context] }.freeze
        @modules = modules.freeze
      end
      private_class_method :update

      update(Set.new)

      def self.register(*modules)
        update(@modules | modules)
      end

      def self.unregister(*modules)
        update(@modules - modules)
      end

      def self.new(*args, &block)
        @current.new(*args, &block)
      end

      def initialize(block = nil)
        @block = block ? Unit.new(nil, &block) : nil
      end

      def block
        unless @block
          e = BlockNotGiven.new("`block' unit cannot use if a block is not given")
          e.set_backtrace(caller)
          raise e
        end

        @block
      end

      def method_missing(method_name, *args, &block)
        e = UnitNotDefined.new("`#{method_name}' unit is not defined")
        e.set_backtrace(caller)
        raise e
      end

      def inspect
        header      = "#{Context.name}:0x%014x" % (object_id << 1)
        module_list = Context.modules.map(&:name).sort * ', '
        with_block  = @block ? ' with a block' : ''
        "#<#{header} [#{module_list}]#{with_block}>"
      end
    end

    class UnitNotDefined < StandardError; end
    class BlockNotGiven  < StandardError; end
  end
end
