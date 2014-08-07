require 'spec_helper'

MD5_CHECKSUM = 'b1c5ef3149e6e0062e1c21c3ce8af7d8'

RSpec.describe SafeMonkeypatch do
  subject { Foo.new }

  before do
    class Foo
      def bar
        "bar"
      end
    end
  end

  it "works as usual" do
    class Foo
      safe_monkeypatch :bar, md5: MD5_CHECKSUM

      def bar
        "patched bar"
      end
    end

    expect(subject.bar).to eq "patched bar"
  end

  it 'raises if none cypher is given' do
    expect {
      class Foo
        safe_monkeypatch :bar

        def bar
          "patch!"
        end
      end
    }.to raise_error SafeMonkeypatch::ConfigurationError
  end

  it "raises if method disappear" do
    expect {
      class Foo
        undef :bar
        safe_monkeypatch :bar, md5: MD5_CHECKSUM

        def bar
          "patched disappeared"
        end
      end
    }.to raise_error SafeMonkeypatch::InvalidMethod
  end

  it "raises if method has changed" do
    expect {
      class Foo
        safe_monkeypatch :bar, md5: 'invalid_checksum'

        def bar
          "patched changed"
        end
      end
    }.to raise_error(
      SafeMonkeypatch::UpstreamChanged,
      /Foo#bar expected to have md5 expected: 'invalid_checksum', but has: '#{MD5_CHECKSUM}'/
    )
  end

  it "accepts custom UnboundMethod" do
    expect {
      safe_monkeypatch Foo.instance_method(:bar), md5: 'another_checksum'
    }.to raise_error(
      SafeMonkeypatch::UpstreamChanged,
      /Foo#bar expected to have md5 expected: 'another_checksum', but has: '#{MD5_CHECKSUM}'/
    )
  end
end
