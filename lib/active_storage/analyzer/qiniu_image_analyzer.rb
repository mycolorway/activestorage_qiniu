module ActiveStorage
  # Extracts width and height in pixels from an image blob.
  #
  # Example:
  #
  #   ActiveStorage::Analyzer::QiniuImageAnalyzer.new(blob).metadata
  #   # => {:size=>39504, :format=>"gif", :width=>708, :height=>576, :colorModel=>"palette0", :frameNumber=>1}
  #
  class Analyzer::QiniuImageAnalyzer < Analyzer
    def self.accept?(blob)
      blob.image?
    end

    def metadata
      code, result, res = Qiniu::HTTP.api_get(blob.service.url(blob.key, fop: 'imageInfo'))
      result.symbolize_keys
    rescue
      {}
    end
  end
end