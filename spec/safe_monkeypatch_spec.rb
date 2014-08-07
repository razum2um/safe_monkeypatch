require 'spec_helper'

class Foo
  def bar
    "bar"
  end
end

# patch
class Foo
  def bar
    "patched bar"
  end
end

RSpec.describe SafeMonkeypatch do
  subject { Foo.new }

  it "works as usual" do
    expect(subject.bar).to eq "patched bar"
  end

  it "raises if method disappear" do

  end

  it "raises if method has changed" do

  end
end
