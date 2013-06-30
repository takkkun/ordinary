require 'ordinary/version'
require 'ordinary/builder'
require 'ordinary/normalizer'
require 'ordinary/module'

module Ordinary

  # Normalize an attribute.
  #
  # @param [Symbol] attr_name an attribute to normalize
  # @param [Symbol] context normalization context. defaults to nil
  # @return [Object] the normalized attribute
  def normalize_attribute(attr_name, context = nil)
    value = __send__(attr_name)

    unless value.nil?
      self.class.normalizers[attr_name.to_sym].each do |normalizer|
        next unless normalizer.coming_under?(self)
        next unless normalizer.run_at?(context)
        value = normalizer.normalize(value)
      end
    end

    value
  end

  # Normalize all attributes and return the normalized object.
  #
  # @param [Symbol] context normalization context. defaults to nil
  # @return [Object] the normalized object
  def normalize(context = nil)
    clone.normalize!(context)
  end

  # Normalize all attributes distructively.
  #
  # @param [Symbol] context normalization context. defaults to nil
  # @return [Object] self
  def normalize!(context = nil)
    unless normalized?(context)
      self.class.normalizers.keys.each do |attr_name|
        __send__(:"#{attr_name}=", normalize_attribute(attr_name, context))
      end

      @normalization_context = context
    end

    self
  end

  # Determine if self is normalized.
  #
  # @param [Symbol] context normalization context. defaults to nil
  # @return whether self is normalized
  def normalized?(context = nil)
    return false unless instance_variable_defined?(:@normalization_context)
    @normalization_context.nil? or (@normalization_context == context)
  end

  # Register modules to the context of building.
  #
  # @scope class
  # @param [Array<Ordinary::Module>] modules modules to register
  def self.register(*modules)
    Builder::Context.register(*modules)
  end

  # Unregister modules from the context of building.
  #
  # @scope class
  # @param [Array<Ordinary::Module>] modules modules to unregister
  def self.unregister(modules)
    Builder::Context.unregister(*modules)
  end

  def self.included(klass)
    klass.extend(ClassMethods)

    if defined?(ActiveModel::Validations) and klass.include?(ActiveModel::Validations)
      method = klass.instance_method(:run_validations!)

      klass.__send__(:define_method, :run_validations!) do
        context = validation_context
        normalized?(context) ? method.bind(self).call : normalize(context).valid?(context)
      end
    end

    if defined?(ActiveRecord::Base) and klass.include?(ActiveRecord::Base)
    end
  end

  module ClassMethods

    # @attribute [r] normalizers
    # @return [Hash<Symbol, Array<Ordinary::Normalizer>>] normalizers for each
    #   attribute
    def normalizers
      @normalizers ||= {}
    end

    # Define normalization for attributes.
    #
    # @example define normalization with a builder for the normalizer
    #
    #   normalizes :name, lambda { lstrip }
    #   normalizes :name, lambda { lstrip | rstrip }
    #
    # @example define normalization with a block
    #
    #   normalizes :name do |value|
    #     value.squeeze(' ')
    #   end
    #
    # @example define normalization with a builder for the normalizer and a block
    #
    #   normalizes :name, -> { lstrip | block | rstrip } do |value|
    #     value.squeeze(' ')
    #   end
    #
    # @param [Array<Symbol>] attr_names attirubte names to normalize
    # @yield [value] normalize the attribute
    # @yieldparam [Object] value value of the attribute to normalize
    def normalizes(*attr_names, &block)
      attr_names = attr_names.dup
      buil       = nil
      options    = {}

      case attr_names.last
      when Proc
        build = attr_names.pop
      when Hash
        options = attr_names.pop.dup
        build = options.delete(:with)
      end

      unless build or block
        raise ArgumentError, 'process for building a normalizer'  \
                             '(with the last argument or :with option) or ' \
                             'an unit of a normalizer ' \
                             '(with block) are not given'
      end

      build ||= lambda { block }
      unit = Builder.new(&block).build(&build)
      normalizer = Normalizer.new(options, &unit)

      attr_names.each do |attr_name|
        raise ArgumentError, "##{attr_name} is not defined"  unless method_defined?(attr_name)
        raise ArgumentError, "##{attr_name}= is not defined" unless method_defined?(:"#{attr_name}=")

        (normalizers[attr_name.to_sym] ||= []) << normalizer

        define_method :"normalized_#{attr_name}" do |context = nil|
          normalize_attribute(attr_name, context)
        end
      end
    end

  end
end
