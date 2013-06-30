require 'ordinary/unit'
require 'set'

module Ordinary
  module Module

    # @attribute [r] requirements
    # @return [Ordinary::Module::Requirements] libraries that the module
    #   requires
    def requirements
      @requirements ||= Requirements.new
    end

    # Add libraries to the requirements.
    #
    # @param [Array<String>] libraries required libraries
    #
    # @see Ordinary::Module#requirements
    def requires(*libraries)
      requirements.add(*libraries)
    end

    # Define an unit for some normalizer.
    #
    # @example define an unit with a block
    #
    #   unit :lstrip do |value|
    #     value.lstrip
    #   end
    #
    #   # same as above
    #   unit :lstrip, lambda { |value| value.lstrip }
    #
    # @example define an unit simply
    #
    #   # call .lstrip of a value
    #   unit :lstrip
    #
    #   # and named "ltrim"
    #   unit :ltrim, :lstrip
    #
    # @example define an unit with existing units
    #
    #   unit :lstrip
    #   unit :rstrip
    #
    #   # use an existing unit
    #   unit :ltrim, lstrip
    #   unit :rtrim, rstrip
    #
    #   # use by combining existing units (by #|, #>> or #<<)
    #   unit :trim, ltrim | rtrim
    #
    # @param [Symbol] name name of the unit
    # @param [Symbol] unit
    # @param [Proc] unit process of normalization that the unit plays
    # @param [Ordinary::Unit, Ordinary::Units] unit an existing unit or
    #   combination existing units
    # @yield [value, *args] process of normalization that the unit plays
    # @yieldparam [Object] value a value to process
    # @yieldparam [Array<Object>] args additional arguments
    def unit(name, unit = nil, &block)
      unit = unit.to_sym if unit.is_a?(String)

      unit = if unit.nil? and block.nil?
               unit_by_send(name)
             elsif unit.is_a?(Symbol)
               unit_by_send(unit)
             elsif unit.is_a?(Proc)
               create_unit(&unit)
             elsif block_given?
               create_unit(&block)
             else
               unit
             end

      unit.owned_by(self, name) unless unit.owned?
      define_method(name) { |*args| args.empty? ? unit : unit.with(*args) }
      module_function name
    end

    private

    def unit_by_send(method_name)
      create_unit { |value, *args| value.__send__(method_name, *args) }
    end

    def create_unit(&process)
      Unit.new(nil, requirements, &process)
    end

    class Requirements
      def initialize
        @libraries = Set.new
        @loaded    = false
      end

      def add(*libraries)
        @loaded    &= !(Set.new(libraries) - @libraries).empty?
        @libraries |= libraries
      end

      def delete(*libraries)
        @libraries -= libraries
      end

      def loaded?
        @loaded
      end

      def load
        @libraries.each(&method(:require))
        @loaded = true
      end
    end
  end
end
