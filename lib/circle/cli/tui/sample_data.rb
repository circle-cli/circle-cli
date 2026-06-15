module Circle
  module CLI
    module TUI
      # Bundled, token-free fixture data shaped like the modern CircleCI v2
      # hierarchy (pipeline -> workflow -> jobs). Used by `circle dashboard
      # --sample` and by the specs so the TUI can be exercised without any
      # network access or real credentials.
      module SampleData
        def self.dashboard
          deep_dup(FIXTURE)
        end

        FIXTURE = {
          project: 'circle-cli/circle-cli',
          branch: 'main',
          pipelines: [
            {
              number: 128,
              created_at: '2026-06-14T18:02:11Z',
              vcs: {
                revision: 'a1b2c3d4e5f6',
                subject: 'Add modern TUI dashboard',
                author: 'Derek Keith'
              },
              workflows: [
                {
                  name: 'build-test-deploy',
                  status: 'running',
                  jobs: [
                    { name: 'checkout',  status: 'success', duration_ms: 3_200 },
                    { name: 'build',     status: 'success', duration_ms: 45_000 },
                    { name: 'rspec',     status: 'running', duration_ms: 12_400 },
                    { name: 'deploy',    status: 'blocked', duration_ms: nil }
                  ]
                },
                {
                  name: 'nightly-security',
                  status: 'on_hold',
                  jobs: [
                    { name: 'audit', status: 'on_hold', duration_ms: nil }
                  ]
                }
              ]
            },
            {
              number: 127,
              created_at: '2026-06-14T15:48:53Z',
              vcs: {
                revision: '9f8e7d6c5b4a',
                subject: 'Fix flaky watcher poll spec',
                author: 'Jean Boussier'
              },
              workflows: [
                {
                  name: 'build-test-deploy',
                  status: 'failed',
                  jobs: [
                    { name: 'checkout', status: 'success', duration_ms: 2_900 },
                    { name: 'build',    status: 'success', duration_ms: 41_500 },
                    { name: 'rspec',    status: 'failed',  duration_ms: 18_900 },
                    { name: 'deploy',   status: 'not_run', duration_ms: nil }
                  ]
                }
              ]
            },
            {
              number: 126,
              created_at: '2026-06-13T22:10:04Z',
              vcs: {
                revision: '1122334455aa',
                subject: 'Bump dependencies and tidy README',
                author: 'Derek Keith'
              },
              workflows: [
                {
                  name: 'build-test-deploy',
                  status: 'success',
                  jobs: [
                    { name: 'checkout', status: 'success', duration_ms: 3_050 },
                    { name: 'build',    status: 'success', duration_ms: 39_800 },
                    { name: 'rspec',    status: 'success', duration_ms: 121_300 },
                    { name: 'deploy',   status: 'success', duration_ms: 27_600 }
                  ]
                }
              ]
            }
          ]
        }.freeze

        # Recursively duplicates the frozen fixture so callers receive a
        # mutable, isolated copy.
        def self.deep_dup(obj)
          case obj
          when Hash
            obj.each_with_object({}) { |(k, v), h| h[k] = deep_dup(v) }
          when Array
            obj.map { |v| deep_dup(v) }
          when String
            obj.dup
          else
            obj
          end
        end
        private_class_method :deep_dup
      end
    end
  end
end
