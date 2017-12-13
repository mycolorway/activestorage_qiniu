# ActivestorageQiniu

Wraps the [Qiniu](https://www.qiniu.com/) Storage Service as an Active Storage service

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activestorage_qiniu'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activestorage_qiniu

## Usage

you can set-up qiniu storage service through the generated <tt>config/storage.yml</tt> file.
```yaml
  qiniu:
    service: Qiniu
    access_key:: <%= ENV['QINIU_ACCESS_KEY'] %>
    secret_key:: <%= ENV['QINIU_SECRET_KEY'] %>
    bucket:: <%= ENV['QINIU_BUCKET'] %>
    domain:: <%= ENV['QINIUDOMAIN'] %>
```
more options. https://github.com/qiniu/ruby-sdk/blob/master/lib/qiniu/auth.rb#L49

Then, in your application's configuration, you can specify the service to use like this:
```ruby
config.active_storage.service = :qiniu
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActivestorageQiniu project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/activestorage_qiniu/blob/master/CODE_OF_CONDUCT.md).
