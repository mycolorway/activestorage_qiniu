module ActiveStorage
  # Wraps the Qiniu Storage Service as an Active Storage service.
  # See ActiveStorage::Service for the generic API documentation that applies to all services.
  #
  #  you can set-up qiniu storage service through the generated <tt>config/storage.yml</tt> file.
  #  For example:
  #
  #   qiniu:
  #     service: Qiniu
  #     access_key: <%= ENV['QINIU_ACCESS_KEY'] %>
  #     secret_key: <%= ENV['QINIU_SECRET_KEY'] %>
  #     bucket: <%= ENV['QINIU_BUCKET'] %>
  #     domain: <%= ENV['QINIUDOMAIN'] %>
  #
  #  more options. https://github.com/qiniu/ruby-sdk/blob/master/lib/qiniu/auth.rb#L49
  #
  # Then, in your application's configuration, you can specify the service to
  # use like this:
  #
  #   config.active_storage.service = :qiniu
  #
  #
  class Service::QiniuService < Service
    attr_reader :bucket, :domain, :upload_options

    def initialize(access_key:, secret_key:, bucket:, domain:, **options)
      @bucket = bucket
      @domain = domain
      protocol = :ssl if options[:protocol] == 'ssl'
      Qiniu.establish_connection! access_key: access_key,
                                  secret_key: secret_key,
                                  protocol: protocol,
                                  **options

      @upload_options = options
    end

    def upload(key, io, checksum: nil)
      instrument :upload, key: key, checksum: checksum do
        begin
          code, result, response_headers = Qiniu::Storage.upload_with_token_2(
            generate_uptoken(key),
            io,
            nil,
            bucket: bucket
          )

          result
        rescue
          raise ActiveStorage::IntegrityError
        end
      end
    end

    def delete(key)
      instrument :delete, key: key do
        Qiniu.delete(bucket, key)
      end
    end

    def delete_prefixed(prefix)
      instrument :delete_prefixed, prefix: prefix do
        items_for(prefix).each { |item| delete item['key'] }
      end
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        answer = items_for(key).any?
        payload[:exist] = answer
        answer
      end
    end

    def url(key, **options)
      instrument :url, key: key do |payload|
        fop = if options[:fop].present?        # 内容预处理
                options[:fop]
              elsif options[:attname].present? # 下载附件
                "attname=#{URI.escape(options[:attname])}"
              end
        url = Qiniu::Auth.authorize_download_url_2(domain, key, fop: fop, expires_in: options[:expires_in])
        payload[:url] = url
        url
      end
    end

    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:)
      instrument :url, key: key do |payload|
        url = Qiniu::Config.up_host(bucket)
        payload[:url] = url
        { url: url, token: generate_uptoken(key, expires_in) }
      end
    end

    def headers_for_direct_upload(key, content_type:, checksum:, **)
      { "Content-Type" => content_type, "Content-MD5" => checksum }
    end

    private

    def items_for(prefix='')
      list_policy = Qiniu::Storage::ListPolicy.new(
        bucket,   # 存储空间
        1000,     # 列举的条目数
        prefix,   # 指定前缀
        ''        # 指定目录分隔符
      )
      code, result, response_headers, s, d = Qiniu::Storage.list(list_policy)
      result['items']
    end

    def generate_uptoken(key=nil, expires_in=nil)
      expires_in ||= 3600
      put_policy = Qiniu::Auth::PutPolicy.new(bucket, key, expires_in)
      upload_options.slice(*Qiniu::Auth::PutPolicy::PARAMS.keys).each do |k, v|
        put_policy.send("#{k}=", v)
      end

      Qiniu::Auth.generate_uptoken(put_policy)
    end
  end
end