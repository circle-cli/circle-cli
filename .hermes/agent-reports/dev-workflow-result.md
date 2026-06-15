# Claude lane result: API v2 workflows/jobs + live dashboard

Branch: `local/modernization-workflow` (local-only; nothing pushed).

## What changed

### API client (`lib/circle/cli/api_client.rb`)
Added three thin wrappers over the existing `get_paged` pagination/error path:
- `project_pipelines(slug, query = {}, max_pages: 1)` — GET `/project/:slug/pipeline`
- `pipeline_workflows(pipeline_id, max_pages: 5)` — GET `/pipeline/:id/workflow`
- `workflow_jobs(workflow_id, max_pages: 5)` — GET `/workflow/:id/job`

All reuse the same auth header, JSON decode, `ApiError` formatting (token redaction), and `next_page_token` walking as the existing client.

### Commands (`lib/circle/cli/app.rb`)
- `circle workflows PIPELINE_ID` — table of name / status / id / created time.
- `circle jobs WORKFLOW_ID` — table of name / status / job number / id / duration.
  Duration is derived from `started_at`/`stopped_at` (h/m/s), `-` when not finished.
- Both validate the token, print a stable `print_table`, and abort with a friendly
  "No workflows/jobs found." on empty results.

### Live dashboard (`lib/circle/cli/tui/data_source.rb`)
- Removed the `PendingIntegration` stub. `LiveDataSource` now takes
  `api:`, `project_slug:`, `branch:` and loads real v2 data:
  latest project pipelines -> workflows -> workflow jobs, mapped into the
  `{ project:, branch:, pipelines:[...] }` shape the renderer consumes.
- Defensive mapping: missing tree branches degrade to empty lists.
- Safe fallback `notice` for no pipelines / no workflows / no jobs.
- `circle dashboard` now wires the live source through the API client; `--sample`
  behavior is unchanged.

### Renderer (`lib/circle/cli/tui/dashboard_renderer.rb`)
- Renders `@data[:notice]` (the fallback messages).
- Shows "No workflows." / "No jobs." for empty branches. Sample-driven specs
  are unaffected (sample data never hits the empty paths).

## Tests
- API specs for the three new methods (HTTP mocked via WebMock; no network).
- App command specs for `workflows` and `jobs` (success + empty/abort + duration).
- `LiveDataSource` specs: full mapping, missing-duration, and all three fallback notices.
- Dashboard command specs: live source render + no-pipelines fallback.
- `bundle exec rake spec` → **109 examples, 0 failures**.
- `circle dashboard --sample --no-color --width 80` renders identically to before.

## Notes
- Legacy `status` (v1) left untouched per the brief.
- Optional live smoke skipped deliberately: it issues a real authenticated request;
  kept strictly local/offline per guardrails. The path is covered by mocked specs.
