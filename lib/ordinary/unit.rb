module Ordinary
  module Composable
    def >>(other)
      Units.new([*self, *other])
    end
    alias | >>

    def <<(other)
      other >> self
    end

    def owner
      owned? ? "#{@module.name}##{@name}" : 'owner unknown'
    end

    def owned_by(mod, name)
      @module = mod
      @name   = name
    end

    def owned?
      @module and @name
    end

    def instance_id
      "#{self.class.name}:0x%014x" % (object_id << 1)
    end
  end

  class Unit
    include Composable

    def initialize(original_unit, requirements = nil, arguments = [], &process)
      raise ArgumentError, 'block not supplied' unless block_given?
      @original_unit = original_unit
      @requirements  = requirements
      @arguments     = arguments
      @process       = process
    end

    attr_reader :requirements

    attr_reader :arguments

    attr_reader :process

    def with(*arguments)
      self.class.new(self, @requirements, arguments, &@process)
    end

    def to_proc
      @requirements.load if @requirements and !@requirements.loaded?
      args = @arguments + (@original_unit ? @original_unit.arguments : [])
      lambda { |value| @process.call(value, *args) }
    end

    def inspect
      original_owner = ''

      if @original_unit
        argument_list  = @arguments.map(&:inspect) * ', '
        original_owner = " (#{@original_unit.owner} with [#{argument_list}])"
      end

      "#<#{instance_id} #{owner}#{original_owner}>"
    end
  end

  class Units < Array
    include Composable

    def with(*arguments)
      self.class.new(map { |unit| unit.with(*arguments) })
    end

    def to_proc
      processes = map(&:to_proc)
      lambda { |value| processes.reduce(value) { |v, p| p.call(v) } }
    end

    def inspect
      "#<#{instance_id} #{owner} [#{map(&:inspect) * ', '}]>"
    end
  end
end
