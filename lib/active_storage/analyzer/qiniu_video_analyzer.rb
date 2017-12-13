module ActiveStorage
  # Extracts width and height in pixels from an image blob.
  #
  # Example:
  #
  #   ActiveStorage::Analyzer::QiniuVideoAnalyzer.new(blob).metadata
  #   # => {:width=>240, :height=>240, :duration=>"2.000000", :aspect_ratio=>"1:1"}
  #
  class Analyzer::QiniuVideoAnalyzer < Analyzer
    def self.accept?(blob)
      blob.video?
    end

    def metadata
      {width: width, height: height, duration: duration, aspect_ratio: aspect_ratio}.compact
    rescue
      {}
    end

    private

    def width
      video_stream['width']
    end

    def hegiht
      video_stream['height']
    end

    def duration
      video_stream['duration']
    end

    def aspect_ratio
      video_stream['display_aspect_ratio']
    end

    def streams
      @streams ||= begin
        code, result, res = Qiniu::HTTP.api_get(blob.service.url(blob.key, fop: 'avinfo'))
        result['streams']
      end
    end

    def video_stream
      @video_stream ||= streams.detect { |stream| stream["codec_type"] == "video" } || {}
    end
  end
end