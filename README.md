# CloudflareAccessEx

Simplifies verification of [Cloudflare Access application tokens][1].

[![Build Status](https://github.com/primait/cloudflare_access_ex/workflows/CI/badge.svg)](https://github.com/primait/cloudflare_access_ex/actions/workflows/ci.yaml)

## Getting started

### Installation

For now, installations should be through git reference. Tags will be available for releases.

```elixir
def deps do
  [
    {:cloudflare_access_ex, "~> 0.1.0"}
  ]
end
```

### Documentation

Docs are currently unpublished. Installation and usage instruction can be found in the [top-level module docs](./lib/cloudflare_access_ex.ex).

## Contributing

We appreciate any contribution. Check our [CONTRIBUTING.md](CONTRIBUTING.md) guide for more information.

### Build/Test

To build & test from source:

```bash
mix deps.get
mix check
```

## Important links

* [Cloudflare Access Application Tokens][1]
* [Validating JWTs (from Cloudflare Docs)][2]

[1]: https://developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/application-token/
[2]: https://developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/validating-json/

## Copyright and License

Copyright (c) 2023, Prima.it.

The source code is licensed under the [MIT License](LICENSE.md).

## TODO

- [ ] Add a test `JwksStrategy`
- [ ] If the keys get rotated unexpectedly, the 'JwksStrategy` signers will be out of date until the next poll.
- [ ] As the `JwksStrategy` module will be called for every request, it is a potential bottleneck.
      Should consider using an ets table or other shared memory mechanism.
- [x] Create a `Plug` module.
- [x] Write a better Readme
- [ ] Consider publishing to hex
- [ ] Consider contributing `JwksStrategy` (if good) back to [joken_jwks](https://github.com/joken-elixir/joken_jwks)
