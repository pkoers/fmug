# AGENTS.md

# FMUG Conference Application

## Purpose

This repository contains the FMUG Conference Application.

The application supports the organisation and operation of FMUG conferences,
including conference information, scheduling and related conference-management
functionality.

When working in this repository, preserve existing behaviour unless a requested
change explicitly requires modifying it.

---

# Technology Stack

The application is primarily built with:

- Ruby on Rails
- Ruby
- PostgreSQL
- HTML / CSS / JavaScript
- Git
- GitHub

Before making assumptions about versions, inspect the repository files such as:

- `.ruby-version`
- `Gemfile`
- `Gemfile.lock`
- `package.json`
- `config/database.yml`
- relevant GitHub Actions workflows

Use the versions and dependencies defined by the repository.

Do not upgrade Ruby, Rails, PostgreSQL, gems, npm packages or other major
dependencies unless the task explicitly requires it.

---

# Development Environments

The project uses the following environments.

## Local development

Development may be performed on macOS.

On Patrick's macOS local development environment, PostgreSQL uses the local
role `pkoers`, not `postgres`. When required for local tests, use:

    PGUSER=pkoers PGPASSWORD=

## LAB01

LAB01 is the physical onsite Ubuntu test server.

Treat LAB01 as a persistent shared test/staging environment.

Do not deploy to LAB01 unless explicitly instructed.

Do not perform destructive database operations on LAB01 without explicit human
approval.

## LAB02

LAB02 is intended to be a disposable/on-demand GitHub Codespaces-based test
environment.

LAB02 may be used for integration and application testing when available.

Do not assume LAB02 is running.

---

# General Working Principles

When given a task:

1. Read this `AGENTS.md` file.
2. Inspect the existing implementation before proposing changes.
3. Identify the smallest reasonable set of files that need modification.
4. Follow existing project conventions and patterns.
5. Prefer modifying existing abstractions over creating duplicate functionality.
6. Implement only what is required by the task.
7. Add or update tests where appropriate.
8. Run relevant tests.
9. Run linting/static analysis if configured.
10. Review the final diff before declaring the task complete.

Do not make unrelated cleanup changes.

Do not refactor unrelated code merely because an alternative implementation
appears preferable.

If requirements are ambiguous and the ambiguity could materially affect
application behaviour, stop and explain the ambiguity rather than making a
large assumption.

## Repository Documentation

Do not modify `README.md` unless the task explicitly requires a README change.
This applies even when additional documentation would be useful. Do not add
setup instructions, operational procedures, implementation notes,
authentication instructions, development instructions, or other information to
`README.md` merely as a consequence of implementing another task. A general
instruction to document a change does not authorize modifying `README.md`.
If a README change appears useful but is not explicitly part of the task,
leave `README.md` unchanged and mention the suggested documentation change
in the completion report or PR Risks / Follow-up section.

---

# Git Workflow

Codex may autonomously:

- create a dedicated feature, fix, refactor, or test branch
- create and use Git worktrees for assigned tasks
- commit validated changes to its own task branch
- push its own task branch to origin
- create a pull request against `main`
- update its own open pull request after CI failures or review feedback
- inspect GitHub CI/check results and PR feedback
- create additional commits needed to correct its own PR

Codex must not:

- commit or push directly to `main`
- merge a pull request
- force-push a shared branch
- rewrite shared Git history
- modify another agent's task branch unless explicitly instructed

An agent should normally work only on the branch/worktree created for its
assigned task.

Suggested naming conventions:

- `feature/<short-description>`
- `fix/<short-description>`
- `refactor/<short-description>`
- `test/<short-description>`

Keep commits focused on the requested task.

---

# Before Making Changes

Before modifying code:

1. Inspect `git status`.
2. Identify the current branch.
3. Inspect relevant models, controllers, views, services, helpers and tests.
4. Search the repository for existing implementations of similar functionality.
5. Check existing database schema and migrations when database changes may be
   involved.

Never overwrite unrelated uncommitted work.

If unrelated uncommitted changes are present, preserve them.

---

# Rails Guidelines

Follow standard Rails conventions unless the existing application deliberately
uses another pattern.

Prefer:

- RESTful routes
- conventional Rails controllers
- Active Record validations
- model associations
- reusable partials
- Rails helpers where appropriate
- service objects only when they genuinely simplify complex business logic

Avoid unnecessary abstractions.

Do not introduce a new framework, architecture pattern or major dependency
without explicit approval.

Use Rails generators where appropriate, but review generated files and remove
unnecessary generated content.

---

# Database Changes

Database changes must be performed through Rails migrations.

Never manually modify `schema.rb` as a substitute for a migration.

Before creating a migration:

1. Inspect the existing schema.
2. Inspect related models.
3. Inspect recent migrations for project conventions.

Migrations should be reversible whenever practical.

Never:

- drop tables
- delete columns
- destroy production/staging data
- truncate tables
- reset databases

without explicit human approval.

Potentially destructive migrations must be clearly identified in the final
report.

---

# Testing

Changes should not knowingly break existing tests.

For application behaviour changes:

- add tests for new behaviour
- update tests when expected behaviour intentionally changes
- include relevant edge cases
- test validations where appropriate
- test authorization/access restrictions where applicable

Before declaring implementation complete, run the relevant test suite.

If the entire test suite is reasonably practical, run it.

If a test cannot be run, explicitly state:

- which test was not run
- why it was not run

Never claim that tests passed unless they were actually executed.

---

# Code Quality

Follow the formatting and linting configuration already present in the
repository.

If RuboCop is configured, run it against changed Ruby files or the project as
appropriate.

Do not perform repository-wide automatic formatting unless explicitly
requested.

Avoid introducing:

- dead code
- commented-out code
- unnecessary dependencies
- duplicated business logic
- debugging output
- temporary files

---

# Security

Never commit secrets.

This includes:

- passwords
- API keys
- tokens
- private keys
- database credentials
- production credentials
- `.env` contents

Use the project's existing credential/environment-variable mechanism.

Do not expose secrets in:

- source code
- logs
- tests
- commits
- pull requests
- screenshots
- generated documentation

Treat all tracked repository content as potentially public. Information that
is not a password, credential, token, or secret is not automatically
appropriate for publication. Do not publish personal contact information,
administrator-account details, internal operational procedures,
authentication/token-generation procedures, private infrastructure information,
or other non-public information unless the task explicitly requires
publication and doing so is appropriate. If internal documentation would be
useful but there is no approved private documentation location, report that need
to the human instead of committing the information elsewhere in the repository.
Do not circumvent the `README.md` rule by placing information that would have
gone into `README.md` into another tracked file.

Treat external input as untrusted.

Use Rails security mechanisms for:

- parameter handling
- authentication
- authorization
- CSRF protection
- escaping/output handling

Do not weaken existing security controls without explicit approval.

---

# Dependencies

Do not add gems, npm packages or other dependencies unless there is a clear
technical reason.

Before adding a dependency, determine whether the required functionality can
reasonably be implemented using:

1. Rails itself
2. Ruby standard library
3. an existing project dependency

If a new dependency is required, explain why.

Do not perform broad dependency upgrades as part of an unrelated task.

---

# UI and UX Changes

Preserve the existing FMUG visual language and interaction patterns.

Before creating new UI components, inspect similar existing pages.

Prefer reusing:

- existing layouts
- partials
- CSS classes
- components
- form patterns
- navigation patterns

Do not redesign unrelated parts of the application.

User-visible text should be clear and concise.

---

# Feature Implementation Workflow

For a substantial new feature, first produce a short implementation plan.

The plan should identify:

1. relevant existing functionality
2. files/components likely to change
3. database changes, if any
4. expected tests
5. risks or ambiguities

Then implement the feature.

Do not create an unnecessarily large architecture document for straightforward
changes.

## Normal Autonomous Task Lifecycle

For a normal implementation task Codex should:

1. Read `AGENTS.md`.
2. Inspect repository status and relevant implementation.
3. Create an appropriate task branch/worktree.
4. Implement the smallest appropriate change.
5. Add/update tests.
6. Run targeted tests.
7. Run the appropriate broader test and quality suite.
8. Review its own diff.
9. Commit validated changes.
10. Push its task branch.
11. Create a pull request, linking it to the originating GitHub Issue when the
    work originated from one.
12. Observe CI results.
13. If CI fails because of the change, investigate and update the PR.
14. When CI is green, present the PR to the human for review.
15. Stop before merge.

---

# Bug Fix Workflow

For bug fixes:

1. reproduce or understand the reported problem
2. identify the root cause
3. prefer adding a regression test demonstrating the problem
4. implement the smallest reasonable fix
5. verify the regression test passes
6. run related tests

Do not merely suppress an error without understanding its cause.

---

# Review Requirements

Before completing a task, review the Git diff.

Check specifically for:

- unintended changes
- debugging code
- security issues
- missing tests
- unnecessary complexity
- duplicated code
- N+1 database queries
- incorrect validations
- migration safety
- accidental credentials
- unrelated formatting changes

---

# Pull Requests

For implementation tasks, pull-request creation is part of the normal
autonomous workflow. A completed implementation should normally result in a
pull request containing:

When work originates from a GitHub Issue, the pull request must link to that
Issue. Normally use a GitHub closing keyword in the PR description:

    Closes #<issue-number>

`Fixes` or `Resolves` may be used when more appropriate. Do not use a closing
keyword if the PR only partially addresses the Issue; reference the Issue
without automatically closing it in that case.

## Summary

What changed and why.

## Implementation

The important implementation details.

## Testing

Tests and checks actually executed.

## Database Changes

Describe migrations or state that there are none.

## Manual Testing

Any useful manual verification steps.

## Risks / Follow-up

Known limitations, risks or work that should be handled separately.

Codex may create and update this pull request autonomously.

Do not declare a PR ready for human review while required tests or CI checks
are failing, unless the failure is clearly identified as unrelated and is
explicitly reported.

The normal handoff point to the human is a validated PR ready for review and
merge.

---

# Human Approval Required

Do not perform the following without explicit human instruction:

- merge into `main`
- push directly to `main`
- deploy to LAB01
- deploy to production
- destructive staging/production database operations
- destructive or irreversible migrations
- credentials, tokens, secrets or external account configuration
- change repository security settings
- change GitHub branch protection
- force-push shared branches
- real Brevo email or other externally visible communication
- irreversible external-system actions
- broad framework or dependency upgrades unless explicitly assigned

Feature-branch pushes and pull-request creation do not require human approval.

When uncertain whether an operation is destructive or externally visible,
request approval.

---

# Completion Report

When finishing an implementation task, provide:

1. Summary of what was changed
2. Files changed
3. Tests executed and their results
4. Lint/static-analysis results, if applicable
5. Database migrations created, if any
6. Anything that was not tested
7. Remaining risks or recommended follow-up

Keep the report concise.

---

# Core Principle

Act as a careful contributor to an existing production-quality Rails
application.

Understand before changing.

Prefer small, reviewable changes.

Test what you change.

Maximize useful autonomy within clearly defined safety boundaries.

Codex should complete routine development work independently when it can do so
safely and verify the result.

Escalate to the human at defined approval boundaries or when a material
product decision cannot be inferred safely.
# Project-Specific Architecture Notes

## Application Architecture

- FMUG is a Rails 8.1 application running Ruby 3.4.2.
- PostgreSQL is the primary database.
- The application is a conventional Rails monolith.
- Server-rendered UI uses ERB.
- Frontend technologies include Importmap, Turbo, Stimulus, Propshaft and
  Tailwind Rails.
- Active Storage is used for attachments.
- Solid Queue, Solid Cache and Solid Cable are used for Rails background jobs,
  caching and Action Cable infrastructure.

Always inspect the current repository configuration before making assumptions
about these components.

## Testing

The project's actual test suite is Minitest under `test/`.

Use:

    bin/rails test

for the Rails test suite.

For targeted testing, use:

    bin/rails test test/path/to/file_test.rb

System tests are located under:

    test/system

Do not assume RSpec is the project's test framework merely because an RSpec
dependency or historical RSpec configuration exists.

The current GitHub Actions configuration may contain historical references to
RSpec. Treat these as configuration to be investigated rather than evidence
that RSpec is the intended test framework.

## Frontend

The landing page currently contains a significant amount of the application's
registration, invitation, modal and agenda-toggle UI.

Before changing these flows, inspect:

    app/views/pages/landing.html.erb

The frontend currently contains a mixture of Rails asset tooling, Importmap,
Tailwind and Shoelace integration.

Do not introduce or assume an npm/Yarn build pipeline without first inspecting
the existing frontend configuration.

Avoid increasing the amount of inline JavaScript or CSS when implementing new
functionality.

When practical, prefer moving new interactive behaviour into appropriately
structured Stimulus controllers rather than adding additional inline
JavaScript.

Do not perform a broad frontend refactor as part of an unrelated feature.

## Authentication and Authorization

Authentication is session-based.

Supported authentication mechanisms include:

- Google OAuth
- email login magic links
- invitation/activation magic links

Magic-link and invitation tokens are digest-backed.

Authorization currently uses application-level login/admin checks.

Preserve existing authentication and authorization behaviour unless explicitly
asked to change it.

Changes involving authentication, invitations, magic links, administrator
permissions or member access require appropriate tests.

## Email

Email delivery is abstracted through `EmailDeliveryService`.

Email may be exported locally or delivered through Brevo depending on the
environment/configuration.

Never send real Brevo emails unless explicitly instructed.

Tests involving email should use the project's existing test/stub mechanisms
and must not contact the real Brevo service.

## Conference Domain Rules

A single `Conference.current` record drives important application behaviour,
including:

- the public landing page
- registration
- invitations
- schedule creation

Treat changes to current-conference behaviour as potentially high impact.

`Schedule` records are intended to belong to the current conference.

Before changing conference, registration, invitation or schedule behaviour,
inspect the related models, controllers and tests together.

## Deployment

Production deployment is intended to use Docker and Kamal.

The current `config/deploy.yml` contains placeholder configuration and must not
be treated as production-ready.

Do not attempt a Kamal deployment unless explicitly instructed and the
deployment configuration has first been reviewed.

LAB01 remains the persistent Ubuntu test/staging environment.

Deployment to LAB01 requires explicit human approval.

LAB02 is intended to be an on-demand/disposable GitHub Codespaces integration
environment.
