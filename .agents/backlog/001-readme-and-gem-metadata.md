As a `person who wants to use Anthropic models from elelem`, I `want a
README and clear RubyGems links for elelem-anthropic`, so that `I can
set my key and options without reading the code and find the docs and
backlog from the gem page`.

# SYNOPSIS

Add a README, and point the gem's RubyGems links at elelem.sh and this
repository's backlog.

# DESCRIPTION

Two small changes that both shape what a newcomer sees first.

## README

The repository has no README. It should cover:

* Install, and selecting a provider: `-p anthropic` or `-p vertex`, and
  `--model NAME`.
* Anthropic API: `ANTHROPIC_API_KEY` (required) and `ANTHROPIC_MODEL`
  (default as set in lib/elelem/anthropic.rb).
* Google Vertex: `GOOGLE_CLOUD_PROJECT` (required),
  `GOOGLE_CLOUD_REGION` (default `us-east5`), `VERTEX_MODEL`, and that
  the token comes from `gcloud auth application-default
  print-access-token`.
* Options for both: `ANTHROPIC_MAX_TOKENS`, `ANTHROPIC_THINKING`,
  `ANTHROPIC_EFFORT`, and that a set but empty variable counts as
  unset.
* The executables in exe/ (`elelem-anthropic`, `elelem-cxml`) and what
  each is for.
* A link to https://elelem.sh/plugins/anthropic/ for the full guide.

The elelem.sh plugin page can be the source for the text. Show commands
without a leading `$`, so they can be pasted.

## Gem metadata

RubyGems shows `homepage_uri` and the other `metadata` links on every
gem page. Today `elelem-anthropic.gemspec` sets `spec.homepage`
to the site root (https://elelem.sh) and sets only `homepage_uri`,
`source_code_uri`, `allowed_push_host` and
`rubygems_mfa_required`.
There is no documentation, bug tracker or changelog link.

Proposed change:

```ruby
spec.homepage = "https://elelem.sh/plugins/anthropic/"
spec.metadata["homepage_uri"] = spec.homepage
spec.metadata["source_code_uri"] = "https://github.com/elelem-sh/anthropic"
spec.metadata["documentation_uri"] = spec.homepage
spec.metadata["bug_tracker_uri"] = "https://github.com/elelem-sh/anthropic/tree/main/.agents/backlog"
spec.metadata["changelog_uri"] = "https://github.com/elelem-sh/anthropic/blob/main/CHANGELOG.md"
```

The original proposal pointed `bug_tracker_uri` at GitHub Issues on
elelem-sh/elelem.sh, filtered by label. That no longer fits: the
project is moving its backlog out of GitHub Issues and into
`.agents/backlog` story files in each repository, so the bug tracker
link points at this repository's backlog directory instead.

/man/anthropic/ redirects to /plugins/anthropic/ on elelem.sh, so a
separate documentation_uri adds nothing. Point both at the plugin page.
CHANGELOG.md exists on main, so the changelog link works today.

Keep `allowed_push_host` and `rubygems_mfa_required` as they are.
RubyGems only shows the new links after the next release.

# SEE ALSO

* [ ] lib/elelem/anthropic.rb:25-50 - anthropic and vertex providers
* [ ] lib/elelem/anthropic/provider.rb - options_from
* [ ] exe/elelem-anthropic, exe/elelem-cxml
* [ ] elelem-anthropic.gemspec:13 - spec.homepage and metadata
* [ ] https://elelem.sh/plugins/anthropic/ - source for README text
* [ ] Formerly elelem-sh/elelem.sh#23
* [ ] Formerly elelem-sh/elelem.sh#41

# Tasks

* [ ] TBD (filled in design mode)

# Acceptance Criteria

* [ ] README.md exists and covers the points above
* [ ] Defaults in the README match the code
* [ ] Commands in the README have no leading `$`
* [ ] `spec.homepage` and `homepage_uri` are https://elelem.sh/plugins/anthropic/
* [ ] `bug_tracker_uri` points at this repository's `.agents/backlog`,
      not at GitHub Issues
* [ ] `changelog_uri` and `source_code_uri` point at this repository
* [ ] `gem build` succeeds and `gem spec` on the built gem shows every
      link
