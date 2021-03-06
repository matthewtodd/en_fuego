class FormattedError < RuntimeError
  def initialize
    super format
  end

  def format
    message = StringIO.new
    message.puts
    message.puts separator

    sections.each do |section|
      message.puts section.strip
      message.puts separator
    end

    message.string.rstrip
  end

  def separator
    '-' * 72
  end

  def format_hash(hash)
    hash.to_a.sort.map { |k,v| "#{k}: #{format_value(v)}" }.join("\n")
  end

  def format_value(value)
    case value
    when Array, Hash
      value.inspect
    else
      value.to_s
    end
  end
end

class MissingElement < FormattedError
  def initialize(type, value, page)
    @type = type
    @value = value
    @page = page
    super()
  end

  def sections
    ["Could not find #{@type} \"#{@value}\" at #{@page.uri}.", @page.body]
  end
end

class MissingXpath < FormattedError
  def initialize(text, page)
    @text = text
    @page = page
    super()
  end

  def sections
    ["Could not find expression \"#{@text}\" at #{@page.uri}.", @page.body]
  end
end

class OAuthSignatureError < FormattedError
  def initialize(signature, consumer, access_token)
    @signature    = signature
    @consumer     = consumer
    @access_token = access_token
    super()
  end

  # TODO a method called align_colons would be nice...
  def sections
    [
      "Expected: #{@signature.signature}\n     Was: #{@signature.request.signature}",
      format_hash(@signature.request.request.env),
      @signature.request.request.body.read,
      "Consumer Secret:\nServer:  #{@consumer.secret}\nRequest: #{@signature.consumer_secret}",
      "Token Secret:\nServer:  #{@access_token.secret}\nRequest: #{@signature.token_secret}"
    ]
  end
end

class UnimplementedRequest < FormattedError
  def initialize(request, options={})
    @request = request
    @options = options
    super()
  end

  def sections
    sections = []
    sections.push "#{method} to #{url}"
    sections.push headers if @options[:headers]
    sections.push body    if @options[:body]
    sections
  end

  def method
    @request.env['REQUEST_METHOD']
  end

  def url
    @request.url
  end

  def headers
    format_hash(@request.env)
  end

  def body
    @request.body.rewind
    @request.body.read
  end
end
