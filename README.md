# Croissant

[![Gem Version](https://img.shields.io/gem/v/croissant)](https://rubygems.org/gems/croissant)
[![License](https://img.shields.io/github/license/userlist/croissant)](https://github.com/userlist/croissant/blob/main/LICENSE.txt)
[![Issues](https://img.shields.io/github/issues/userlist/croissant)](https://github.com/userlist/croissant/issues)
[![Build Status](https://github.com/userlist/croissant/workflows/Ruby/badge.svg)](https://github.com/userlist/croissant)

**Modern processing pipeline for HTML emails**

Croissant parses the HTML and CSS and applies a series of transformations that make it render more consistently across email clients. The best known of those transformations is CSS inlining, but the library is built as a pipeline, so inlining is one composable step among several rather than the whole library.

Croissant brings its own CSS parser, its own selector engine, and its own implementation of the cascade.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add croissant
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install croissant
```

## Usage

### Quick start

```ruby
require 'croissant'

Croissant.process(html)
```

Given this input:

```html
<!doctype html>
<html>
  <head>
    <style>
      .wrapper { -croissant-width: 600; -croissant-align: center }
      .cell { background-color: #2563eb; text-align: center; padding: 12px 24px }
      .button { color: #ffffff }
      .cell:hover { background-color: #1d4ed8 }
      @media (max-width: 600px) { .wrapper { width: 100% } }
    </style>
  </head>
  <body>
    <table class="wrapper">
      <tr>
        <td class="cell"><a class="button" href="https://example.com">Confirm your email</a></td>
      </tr>
    </table>
  </body>
</html>
```

`Croissant.process` returns:

```html
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <style>.cell:hover{background-color:#1d4ed8} @media (max-width: 600px){.wrapper{width:100%}}</style>
  </head>
  <body>
    <table class="wrapper" align="center" width="600">
      <tr>
        <td class="cell" style="background-color:#2563eb;text-align:center;padding:12px 24px" align="center" bgcolor="#2563eb"><a class="button" href="https://example.com" style="color:#ffffff">Confirm your email</a></td>
      </tr>
    </table>
  </body>
</html>
```

The inlinable rules moved into `style` attributes. The `:hover` rule and the media query cannot be expressed as an inline style, so they are kept in a `<style>` element instead of being thrown away. (The `Content-Type` meta element is added by Nokogiri when it parses a full document.)

Some email clients ignore CSS but still honor the old HTML presentational attributes, so Croissant mirrors supported properties into them as well: the cell's `background-color` and `text-align` also become `bgcolor` and `align`. Properties prefixed with `-croissant-` exist only to produce an attribute and are removed from the style afterwards. That is how the table gets `width="600"` and `align="center"` without any inline style of its own.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/userlist/croissant. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/userlist/croissant/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Croissant project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/userlist/croissant/blob/main/CODE_OF_CONDUCT.md).

## What is Userlist?

[![Userlist](https://userlist.com/images/external/userlist-logo-github.svg)](https://userlist.com/)

[Userlist](https://userlist.com/) allows you to onboard and engage your SaaS users with targeted behavior-based campaigns using email or in-app messages.

Userlist was started in 2017 as an alternative to bulky enterprise messaging tools. We believe that running SaaS products should be more enjoyable. Learn more [about us](https://userlist.com/about-us/).
