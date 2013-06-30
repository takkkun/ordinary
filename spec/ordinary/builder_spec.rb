require 'ordinary/builder'

describe Ordinary::Builder do
  describe '#context' do
    subject { described_class.new { }.context }

    it          { should be_an(Ordinary::Builder::Context.current) }
    its(:block) { should_not be_nil }
  end

  describe '#build' do
    it '' do
    end

    context '' do
      # it '' do
      #   build = lambda { a }
      #   builder = Ordinary::Builder.new(build)
      #   builder.build
      # end
    end
  end
end

describe Ordinary::Builder::Context do
  before { described_class.__send__(:update, Set.new) }

  def change_for_current_ancestors(*modules)
    change(described_class, :current) do
      described_class.current.ancestors.select { |mod| modules.include?(mod) }
    end
  end

  def change_for_modules
    change(described_class, :modules)
  end

  describe '.register' do
    it do
      expect {
        described_class.register(Math)
      }.to change_for_current_ancestors(Math).from([]).to([Math])
    end

    it do
      expect {
        described_class.register(Math)
      }.to change_for_modules.from(Set.new).to(Set.new([Math]))
    end
  end

  describe '.unregister' do
    before { described_class.register(Math) }

    it do
      expect {
        described_class.unregister(Math)
      }.to change_for_current_ancestors(Math).from([Math]).to([])
    end

    it do
      expect {
        described_class.unregister(Math)
      }.to change_for_modules.from(Set.new([Math])).to(Set.new)
    end
  end

  describe '.new' do
    before do
      @original = described_class.current
      described_class.instance_variable_set(:@current, Class.new)
    end

    after do
      described_class.instance_variable_set(:@current, @original)
    end

    subject { described_class.new }

    it { should be_a(described_class.current) }

    it "should call #{described_class}.current.new with same arguments and same block" do
      described_class.current.should_receive(:new).with('arg1', 'arg2').and_yield
      described_class.new('arg1', 'arg2') { }
    end
  end

  describe '#block' do
    let (:sample_block) { lambda { } }

    subject { context.block }

    context 'with a block at construction' do
      let (:context) { described_class.new(sample_block) }

      it            { should be_an(Ordinary::Unit) }
      its(:process) { should be(sample_block) }
    end

    context 'with no block at construction' do
      let (:context) { described_class.new }

      it { expect { subject }.to raise_error(Ordinary::Builder::BlockNotGiven) }
    end
  end

  describe '#undefined_method' do
    it do
      expect {
        described_class.new.undefined_method
      }.to raise_error(Ordinary::Builder::UnitNotDefined, "`undefined_method' unit is not defined")
    end
  end

  describe '#inspect' do
    let (:header)      { "#{described_class.name}:0x%014x" % (context.object_id << 1) }
    let (:module_list) { modules.map(&:name).sort * ', ' }
    let (:modules)     { [Math, Enumerable] }

    subject { context.inspect }

    before { described_class.register(*modules) }
    after  { described_class.unregister(*modules) }

    context 'with a block at construction' do
      let (:context) { described_class.new(lambda { }) }

      it { should be == "#<#{header} [#{module_list}] with a block>" }
    end

    context 'with no block at construction' do
      let (:context) { described_class.new }

      it { should be == "#<#{header} [#{module_list}]>" }
    end
  end
end
