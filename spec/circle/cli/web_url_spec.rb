require 'spec_helper'
require 'circle/cli/web_url'

module Circle::CLI
  RSpec.describe WebUrl do
    describe '.pipeline' do
      it 'builds an app.circleci.com URL with the long VCS segment' do
        expect(WebUrl.pipeline('gh/acme/widgets', 42))
          .to eq('https://app.circleci.com/pipelines/github/acme/widgets/42')
      end

      it 'maps the bitbucket short prefix' do
        expect(WebUrl.pipeline('bb/acme/widgets', 7))
          .to eq('https://app.circleci.com/pipelines/bitbucket/acme/widgets/7')
      end

      it 'passes unknown VCS prefixes through untouched' do
        expect(WebUrl.pipeline('circleci/acme/widgets', 7))
          .to eq('https://app.circleci.com/pipelines/circleci/acme/widgets/7')
      end

      it 'returns nil when the number is missing' do
        expect(WebUrl.pipeline('gh/acme/widgets', nil)).to be_nil
      end
    end

    describe '.workflow' do
      it 'appends the workflow id to the pipeline URL' do
        expect(WebUrl.workflow('gh/acme/widgets', 42, 'wf-123'))
          .to eq('https://app.circleci.com/pipelines/github/acme/widgets/42/workflows/wf-123')
      end

      it 'falls back to the pipeline URL when no workflow id is given' do
        expect(WebUrl.workflow('gh/acme/widgets', 42, nil))
          .to eq('https://app.circleci.com/pipelines/github/acme/widgets/42')
      end
    end
  end
end
