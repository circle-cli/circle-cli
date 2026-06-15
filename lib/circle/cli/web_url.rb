module Circle
  module CLI
    # Builds canonical app.circleci.com web URLs from an API v2 project slug
    # ("vcs/org/repo") plus pipeline/workflow identifiers. The modern web app
    # expects the long VCS form ("github"/"bitbucket"), so the short slug
    # prefixes the API uses ("gh"/"bb") are mapped across.
    module WebUrl
      APP_HOST = 'https://app.circleci.com'.freeze

      VCS_SEGMENTS = {
        'gh' => 'github',
        'bb' => 'bitbucket'
      }.freeze

      # Web URL for a pipeline by its project-scoped number. Returns nil when
      # the slug or number is missing so callers can degrade rather than build
      # a broken link.
      def self.pipeline(slug, number)
        return nil unless slug && number
        "#{APP_HOST}/pipelines/#{normalize(slug)}/#{number}"
      end

      # Web URL for a specific workflow within a pipeline.
      def self.workflow(slug, number, workflow_id)
        base = pipeline(slug, number)
        return base unless base && workflow_id
        "#{base}/workflows/#{workflow_id}"
      end

      # Maps the API slug ("gh/org/repo") to the web app's path form
      # ("github/org/repo"). Unknown VCS prefixes pass through untouched.
      def self.normalize(slug)
        parts = slug.to_s.split('/')
        return slug.to_s if parts.length < 3

        vcs = parts.shift
        "#{VCS_SEGMENTS.fetch(vcs, vcs)}/#{parts.join('/')}"
      end
    end
  end
end
