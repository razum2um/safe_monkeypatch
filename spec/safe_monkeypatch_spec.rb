require 'spec_helper'

MD5_CHECKSUM = 'b1c5ef3149e6e0062e1c21c3ce8af7d8'
SHA1_CHECKSUM = '31c701df5f245ac40a1f8cc958c77e4c4fa815df'

RSpec.describe SafeMonkeypatch do
  subject { Foo.new }

  before do
    class Foo
      def bar
        "bar"
      end
    end
  end

  it "works" do
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
      /Foo#bar expected to have md5 expected: "invalid_checksum", but has: "#{MD5_CHECKSUM}"/
    )
  end

  it "accepts custom UnboundMethod" do
    expect {
      Foo.safe_monkeypatch Foo.instance_method(:bar), md5: 'another_checksum'
    }.to raise_error(
      SafeMonkeypatch::UpstreamChanged,
      /Foo#bar expected to have md5 expected: "another_checksum", but has: "#{MD5_CHECKSUM}"/
    )
  end

  describe "multiple cyphers" do
    it "works" do
      class Foo
        safe_monkeypatch :bar, md5: MD5_CHECKSUM, sha1: SHA1_CHECKSUM

        def bar
          "patched bar"
        end
      end

      expect(subject.bar).to eq "patched bar"
    end

    it "fails if some cypher is invalid" do
      expect {
        class Foo
          safe_monkeypatch :bar, md5: MD5_CHECKSUM, sha1: 'invalid'

          def bar
            "patched bar"
          end
        end
      }.to raise_error(
        SafeMonkeypatch::UpstreamChanged,
        /Foo#bar expected to have sha1 expected: "invalid", but has: "#{SHA1_CHECKSUM}"/
      )
    end

    it "works with mutlipatch" do
      expect(Kernel).to receive(:puts).once

      class Foo
        safe_monkeypatch :bar, md5: MD5_CHECKSUM, sha1: SHA1_CHECKSUM do
          Kernel.puts

          def bar
            "patched bar"
          end
        end
      end

      expect(subject.bar).to eq "patched bar"
    end
  end

  describe "multipatching" do
    it "works" do
      class Foo
        safe_monkeypatch :bar, md5: 'invalid_checksum' do
          def bar
            "invalid patch"
          end
        end

        safe_monkeypatch :bar, md5: MD5_CHECKSUM do
          def bar
            "patched bar"
          end
        end

        safe_monkeypatch :bar, md5: 'another_checksum' do
          def bar
            "another patch"
          end
        end
      end

      expect(subject.bar).to eq "patched bar"
    end

    it "doesn't complain if no matching block found" do
      class Foo
        safe_monkeypatch :bar, md5: 'invalid_checksum' do
          def bar
            "invalid patch"
          end
        end
      end

      expect(subject.bar).to eq "bar"
    end

    it "complains if no matching block found if array given" do
      expect {
        class Foo
          safe_monkeypatch :bar, md5: ['invalid_checksum', 'another_checksum']

          safe_monkeypatch :bar, md5: 'invalid_checksum' do
            def bar
              "invalid patch"
            end
          end

          safe_monkeypatch :bar, md5: 'another_checksum' do
            def bar
              "invalid patch"
            end
          end
        end
      }.to raise_error(
        SafeMonkeypatch::UpstreamChanged,
        /Foo#bar expected to have md5 expected: \["invalid_checksum", "another_checksum"\], but has: "#{MD5_CHECKSUM}"/
      )
    end
  end
end
