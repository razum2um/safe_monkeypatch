require "digest"
require "method_source"

module SafeMonkeypatch
  class UpstreamChanged < StandardError
  end

  class ConfigurationError < StandardError
  end

  class InvalidMethod < StandardError
  end
end

class Module
  def safe_monkeypatch(meth, options={})
    options = options.dup
    info = options.delete(:error)

    if meth.is_a? UnboundMethod
      method = meth
    else
      begin
        method = instance_method(meth)
      rescue NameError => e
        raise SafeMonkeypatch::InvalidMethod, "#{inspect} has no method #{meth} anymore"
      end
    end

    source = method.source

    if options.empty?
      raise SafeMonkeypatch::ConfigurationError, "Provide at least one cypher name like: md5: '...'"
    end

    options.each do |cypher_name, expected|
      cypher = Digest.const_get(cypher_name.upcase)
      if (actual = cypher.hexdigest(source)) != expected
        raise SafeMonkeypatch::UpstreamChanged, "#{inspect}##{meth} expected to have #{cypher_name} expected: '#{expected}', but has: '#{actual}'\n#{info}".strip
      end
    end
  end
end

# Module.send :include, SafeMonkeypatch

