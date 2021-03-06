require "digest"
require "method_source"

module SafeMonkeypatch
  extend self

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
      meth = method.name
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

    found_match = false
    error_parts = ["#{inspect}##{meth} expected to have"]

    options.each do |cypher_name, expected|
      cypher = Digest.const_get(cypher_name.upcase)
      actual = cypher.hexdigest(source)
      found_match = if expected.is_a? Array
                      expected.any? { |e| e == actual }
                    else
                      actual == expected
                    end

      unless found_match
        error_parts << "#{cypher_name} expected: #{expected.inspect}, but has: #{actual.inspect}"
      end
    end

    error_parts << info.to_s if info

    if block_given? && found_match
      yield
    elsif block_given?
      nil # pass
    elsif not found_match
      raise SafeMonkeypatch::UpstreamChanged, error_parts.join(" ")
    end
  end
end

