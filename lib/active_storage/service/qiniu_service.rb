require 'open-uri'
require 'retries'

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
  #     domain: <%= ENV['QINIU_DOMAIN'] %>
  #     protocol: <%= ENV.fetch("QINIU_PROTOCOL") { "http" } %>
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
    BLOCK_SIZE = 4 * 1024 * 1024
    attr_reader :bucket, :domain, :upload_options, :protocol, :bucket_private

    def initialize(access_key:, secret_key:, bucket:, domain:, **options)
      @bucket = bucket
      @domain = domain
      @protocol = (options.delete(:protocol) || 'https').to_sym
      bucket_private = options.delete(:bucket_private)
      @bucket_private = bucket_private.nil? ? false : !!bucket_private
      Qiniu.establish_connection! access_key: access_key,
                                  secret_key: secret_key,
                                  protocol: @protocol,
                                  **options

      @upload_options = options
    end

    def upload(key, io, checksum: nil, content_type: nil, **)
      instrument :upload, key: key, checksum: checksum do
        io = File.open(io) unless io.respond_to?(:read)

        ctx_list = []
        file_size = 0
        while (blk = io.read(BLOCK_SIZE))
          ctx = upload_blk(key, blk)
          file_size += blk.size
          ctx_list.push(ctx)
        end

        api_call(
          key,
          '/' + [
            'mkfile',
            file_size,
            'key',
            encode(key),
            *(content_type ? ['mimeType', encode(content_type)] : [])
          ].join('/'),
          ctx_list.join(',')
        )
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

    def download(key)
      if block_given?
        instrument :streaming_download, key: key do
          open(url(key, disposition: :attachment)) do |file|
            while data = file.read(64.kilobytes)
              yield data
            end
          end
        end
      else
        instrument :download, key: key do
          open(url(key, disposition: :attachment)).read
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        uri = URI(url(key, disposition: :attachment))
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |client|
          client.get(uri, 'Range' => "bytes=#{range.begin}-#{range.exclude_end? ? range.end - 1 : range.end}").body
        end
      end
    end

    def url(key, **options)
      instrument :url, key: key do |payload|
        fop = if options[:fop].present?        # 内容预处理
                options[:fop]
              elsif options[:disposition].to_s == 'attachment' # 下载附件
                attname = URI.escape "#{options[:filename] || key}"
                "attname=#{attname}"
              end

        url = if bucket_private
                expires_in = options[:expires_in] || url_expires_in
                Qiniu::Auth.authorize_download_url_2(domain, key, schema: protocol, fop: fop, expires_in: expires_in)
              else
                url_encoded_key = CGI::escape(key)
                "#{protocol}://#{domain}/#{url_encoded_key}?#{fop}"
              end

        payload[:url] = url
        url
      end
    end

    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:)
      instrument :url, key: key do |payload|
        url = Qiniu::Config.up_host(bucket)
        payload[:url] = url
        url
      end
    end

    def headers_for_direct_upload(key, content_type:, checksum:, **)
      { "Content-Type" => content_type, "Content-MD5" => checksum, "x-token" => generate_uptoken(key) }
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

    def upload_blk(key, blk)
      result =
        with_retries(max_retries: 3) do
          api_call(key, "/mkblk/#{blk.size}", blk)
        end
      result.fetch('ctx')
    end

    def api_call(key, path, body)
      url = Qiniu::Config.up_host(bucket) + path

      response = RestClient.post(
        url,
        body,
        'Authorization' => "UpToken #{generate_uptoken(key)}"
      )

      result = JSON.parse(response.body)

      result
    end

    def encode(value)
      Base64.encode64(value).strip.gsub(/\+/, '-').gsub(%r{/}, '_')
    end
  end
end
