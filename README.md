# SafeMonkeypatch

[![Gem Version][GV img]][Gem Version]
[![Build Status][BS img]][Build Status]

**If you can, please, DO NOT monkeypatch.**

Sometimes I patch ActiveRecord, but ain't sure if
it's gonna break in the next version of Rails. This gem
would raise an error if monkey patched method has changed
since last time you've adapted your patch to the upstream.

## Usage

    # assume some upstream in foo.gem:
    class Foo
      def bar
        puts "do first thing"
        puts "do second thing"
        puts "do something else"
      end
    end

    # your code
    class Foo

      # you can use any of Digest::*** checksum's methods: sha1, etc.
      # NOTE: do this BEFORE monkeypatch happens
      safe_monkeypatch :bar, md5: "", error: "my additional info for exception"

      def bar
        puts "do first thing"
        # puts "do second thing" # don't do that
        puts "do something else"
      end
    end

Until upstream code isn't changed, it's working like usual.
But if the new version changes the implementation of `Foo#bar` method, an
error is raised **while startup time**
(unless you monkeypatch in runtime, but now you're on your own):

    SafeMonkeypatch::UpstreamChanged: Foo#bar expected to have md5 checksum: "", but has: ""
    my additional info for exception

You can also use it without patched module scope (for proper error use patched class/module name):

    Foo.safe_monkeypatch Foo.instance_method(:bar), md5: 'invalid_checksum'

Happy monkeypatching :)

[Gem Version]: https://rubygems.org/gems/safe_monkeypatch
[Build Status]: https://travis-ci.org/razum2um/safe_monkeypatch

[GV img]: https://badge.fury.io/rb/safe_monkeypatch.png
[BS img]: https://travis-ci.org/razum2um/safe_monkeypatch.png
