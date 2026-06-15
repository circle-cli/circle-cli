require 'net/http'
require 'json'
require 'uri'
require 'circle/cli/api_error'

module Circle
  module CLI
    # Minimal CircleCI API v2 client built on Net::HTTP (stdlib, no SDK).
    # Handles token auth, JSON encode/decode, error formatting, and
    # next_page_token pagination.
    class ApiClient
      DEFAULT_BASE_URL = 'https://circleci.com/api/v2'.freeze

      attr_reader :base_url

      def initialize(token:, base_url: DEFAULT_BASE_URL)
        raise ArgumentError, 'a CircleCI token is required' if token.nil? || token.empty?
        @token = token
        @base_url = base_url
      end

      def get(path, query = {})
        request(Net::HTTP::Get, path, query: query)
      end

      def post(path, body = {})
        request(Net::HTTP::Post, path, body: body)
      end

      # Recent pipelines for a project slug ("vcs/org/repo"). Defaults to a
      # single page since the dashboard only needs the newest handful.
      def project_pipelines(slug, query = {}, max_pages: 1)
        get_paged("/project/#{slug}/pipeline", query, max_pages: max_pages)
      end

      # Workflows belonging to a pipeline id.
      def pipeline_workflows(pipeline_id, max_pages: 5)
        get_paged("/pipeline/#{pipeline_id}/workflow", {}, max_pages: max_pages)
      end

      # Jobs belonging to a workflow id.
      def workflow_jobs(workflow_id, max_pages: 5)
        get_paged("/workflow/#{workflow_id}/job", {}, max_pages: max_pages)
      end

      # Walks v2 pagination, concatenating each page's `items` array. Stops when
      # there is no next_page_token or after `max_pages` requests.
      def get_paged(path, query = {}, max_pages: 10)
        items = []
        page_token = nil
        pages = 0

        loop do
          pages += 1
          paged_query = query.dup
          paged_query[:'page-token'] = page_token if page_token
          body = get(path, paged_query)
          items.concat(Array(body['items'])) if body.is_a?(Hash)
          page_token = body.is_a?(Hash) ? body['next_page_token'] : nil
          break if page_token.nil? || page_token.empty? || pages >= max_pages
        end

        items
      end

      private

      def request(klass, path, query: {}, body: nil)
        uri = build_uri(path, query)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')

        req = klass.new(uri.request_uri)
        req['Circle-Token'] = @token
        req['Accept'] = 'application/json'
        if body
          req['Content-Type'] = 'application/json'
          req.body = JSON.generate(body)
        end

        handle(http.request(req))
      rescue ApiError
        raise
      rescue StandardError => e
        raise ApiError.new("Request failed: #{e.message}", token: @token)
      end

      def handle(response)
        code = response.code.to_i
        parsed = parse_body(response.body)
        return parsed if code >= 200 && code < 300

        message =
          if parsed.is_a?(Hash) && parsed['message']
            parsed['message']
          else
            response.body.to_s
          end
        raise ApiError.new(message, status: code, response_body: parsed, token: @token)
      end

      def parse_body(raw)
        return {} if raw.nil? || raw.empty?
        JSON.parse(raw)
      rescue JSON::ParserError
        raw
      end

      def build_uri(path, query)
        normalized = path.start_with?('/') ? path : "/#{path}"
        uri = URI.parse("#{base_url}#{normalized}")
        uri.query = URI.encode_www_form(query) unless query.nil? || query.empty?
        uri
      end
    end
  end
end
