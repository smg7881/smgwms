# Repository Guidelines

## Project Structure & Module Organization
This is a Ruby 4.0.1 / Rails 8.1 app. Core code lives in `app/` (controllers, models, views, jobs, mailers). Configuration is in `config/`, database schema and migrations in `db/`, and tests in `test/`. Frontend assets are split between `app/assets/` (CSS via Propshaft) and `app/javascript/` (Hotwire/Stimulus). Public/static files live in `public/`. SQLite database files are stored under `storage/`. Docs and templates live in `doc/` (see `doc/starter_template/README.md` for patterns).

## Build, Test, and Development Commands
- `bin/rails server`: run the local dev server.
- `bin/rails db:migrate`: apply database migrations.
- `bin/rails db:test:prepare test`: run the full test suite.
- `bin/rails test test/models/post_test.rb`: run a single test file.
- `bin/rails test:system`: run system tests.
- `bin/rubocop`: lint Ruby code (Rails Omakase rules).
- `bin/brakeman --no-pager`: static security scan for Ruby/Rails.
- `bin/bundler-audit`: scan gem vulnerabilities.
- `bin/importmap audit`: audit JS dependencies.

## Coding Style & Naming Conventions
Follow `STYLE.md` and `STYLE_GUIDE.md`. Use 2-space indentation for Ruby. Prefer expanded conditionals over guard clauses except for early returns at the top of a method. Order methods as: class methods, public (with `initialize` at the top), then `private`. Indent under visibility modifiers and do not add a blank line after `private`. Favor thin controllers calling rich model APIs; avoid service objects unless justified. Name async methods with `_later` and sync counterparts with `_now`.

## Testing Guidelines
Tests are Minitest-based under `test/` with fixtures in `test/fixtures/`. Model, controller, and system tests should follow Rails naming conventions (e.g., `test/models/post_test.rb`). Use `bin/rails test` for unit/integration and `bin/rails test:system` for browser/system coverage. No explicit coverage threshold is configured.

## Commit & Pull Request Guidelines
Git history is minimal and does not show a formal commit style. Use concise, imperative subjects (e.g., "Add reports filter") and keep commits focused. For PRs, include a clear description, steps to verify, linked issues (if any), and screenshots or GIFs for UI changes. Ensure linting and security scans pass before requesting review.

## Security & Deployment Notes
Security tooling is part of the workflow (`brakeman`, `bundler-audit`, `importmap audit`). Deployment is containerized with Docker and Kamal (`config/deploy.yml`); keep changes compatible with that setup.
