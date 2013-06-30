module Ordinary
  class Normalizer

    def initialize(options = {}, &process)
      @determine = extract_determiner(options)
      @context   = options[:on]
      @process   = process
    end

    # Normalize a value by the normalizer.
    #
    # @param [Object] value a value to normalize
    # @return [Object] a normalized value
    def normalize(value)
      @process.call(value)
    end

    # Determine if a model coming under a target of the normalizer.
    #
    # @param [ActiveModel::Model] model a model to determine if be a target of
    #   the normalizer
    # @return whether the model is a target of the normalizer
    def coming_under?(model)
      @determine.nil? or !!@determine.call(model)
    end

    # Determine if
    #
    # @param [Symbol] context a context to determine
    # @return whether
    def run_at?(context)
      @context.nil? or (@context == context)
    end

    private

    def extract_determiner(options)
      if determine = options[:if]
        lambda { |model|  model.instance_eval(&determine) }
      elsif determine = options[:unless]
        lambda { |model| !model.instance_eval(&determine) }
      end
    end

  end
end
