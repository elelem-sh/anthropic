# Changelog

## [0.4.0](https://github.com/elelem-sh/anthropic/compare/v0.3.1...v0.4.0) (2026-11-19)


### Features

* cache prompts and stream over a kept-alive connection ([a0a5c67](https://github.com/elelem-sh/anthropic/commit/a0a5c67964d61f012a697c668776d5b8d38515ee))


### Bug Fixes

* leave out an empty system prompt and say when the context window is full ([df97854](https://github.com/elelem-sh/anthropic/commit/df97854090f78afd3e2528fee7c3522e11957219))
* say when a reply hits max_tokens or is refused ([d7f36d1](https://github.com/elelem-sh/anthropic/commit/d7f36d1b2dd731c08b8688d19ec3c9b72edbfeb5))


### Performance Improvements

* keep the gcloud token for three minutes instead of asking on every request ([bf84f19](https://github.com/elelem-sh/anthropic/commit/bf84f19e8a6139105a5734befcc754a57a817ab0))

## [0.3.1](https://github.com/elelem-sh/anthropic/compare/v0.3.0...v0.3.1) (2026-11-18)


### Bug Fixes

* **deps:** accept the json that Ruby 4.0 ships ([07d2e46](https://github.com/elelem-sh/anthropic/commit/07d2e46bc8415fc5eeae9b6860be3f61b06f663f))

## [0.3.0](https://github.com/elelem-sh/anthropic/compare/v0.2.1...v0.3.0) (2026-11-15)


### Features

* accept model: from provider_options, fall back to ENV ([4ce6ce0](https://github.com/elelem-sh/anthropic/commit/4ce6ce0dde481054f3d2825ac752845b86752ded))
* elelem-cxml prints files as XML documents to paste into a prompt ([df0fd5d](https://github.com/elelem-sh/anthropic/commit/df0fd5de3f943bb55ddb2eb46c62f691a8abadcf))


### Bug Fixes

* -p vertex loads, and Vertex streams on streamRawPredict ([elelem-sh/elelem.sh#24](https://github.com/elelem-sh/elelem.sh/issues/24)) ([7a824cd](https://github.com/elelem-sh/anthropic/commit/7a824cd1469db18200e89e5a5a51171c00823d45))
* add rspec to Gemfile so bundle exec rspec runs at all ([a777ac9](https://github.com/elelem-sh/anthropic/commit/a777ac95fb2bbb6c8d712fd77f65001e9735e1ec))
* ANTHROPIC_MAX_TOKENS, ANTHROPIC_THINKING and ANTHROPIC_EFFORT configure requests ([elelem-sh/elelem.sh#25](https://github.com/elelem-sh/elelem.sh/issues/25)) ([de10ea0](https://github.com/elelem-sh/anthropic/commit/de10ea071d3d00649d8cb8a33f21856bdb8dad41))
* default to Sonnet 5.5 on the API and Vertex ([elelem-sh/elelem.sh#25](https://github.com/elelem-sh/elelem.sh/issues/25)) ([fa95d74](https://github.com/elelem-sh/anthropic/commit/fa95d746760d89f9d33efd5ba8dae8705bd37f86))
* empty ANTHROPIC_ settings count as unset, and ANTHROPIC_EFFORT must be a known level ([9110de8](https://github.com/elelem-sh/anthropic/commit/9110de8ddbf0b03d5da6b5d34b353e1b710702de))
* empty model, key and project settings count as unset in elelem-anthropic ([d396f5f](https://github.com/elelem-sh/anthropic/commit/d396f5fbb309bfcd5eeadb27aadd96de7fe782d7))
* raise on a mid-stream error event instead of an empty reply ([b6538c8](https://github.com/elelem-sh/anthropic/commit/b6538c8bbb22c377660f9c38410941d74ba9fa97))
* require elelem ~&gt; 0.12, the floor builtins/skills actually need ([c8a1186](https://github.com/elelem-sh/anthropic/commit/c8a118639d87cc6949f3163a56a940a39e13d0c4))
