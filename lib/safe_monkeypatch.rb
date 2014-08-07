require "digest"
require "method_source"
require "safe_monkeypatch/version"

module SafeMonkeypatch
  def safe_monkeypatch(meth, options={})
    options = options.dup
    info = options.delete(:error)

    begin
      method = instance_method(meth)
    rescue NameError => e
      raise UpstreamChanged, "#{inspect} has no method #{meth} anymore"
    end

    source = method.source

    options.each do |cypher_name, expected|
      cypher = Digest.const_get(cypher_name.upcase)
      if (actual = cypher.hexdigest(source)) != expected
        raise UpstreamChanged, "#{inspect}##{meth} expected to have #{cypher_name} expected: #{expected}, but has: #{actual}\n#{info}"
      end
    end
  end
end

Module.send :extend, SafeMonkeypatch

