# CloudflareAccessEx

## TODO

- [ ] Add a test `JwksStrategy`
- [ ] If the keys get rotated unexpectedly, the 'JwksStrategy` signers will be out of date until the next poll.
- [ ] As the `JwksStrategy` module will be called for every request, it is a potential bottleneck.
      Should consider using an ets table or other shared memory mechanism.
- [ ] Create a `Plug` module.
- [ ] Write a better Readme
- [ ] Consider publishing to hex
- [ ] Consider contributing `JwksStrategy` (if good) back to [joken_jwks](https://github.com/joken-elixir/joken_jwks)

## Installation

For now, installations should be through git reference. Tags will be available for releases.

```elixir
def deps do
  [
    {:cloudflare_access_ex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/cloudflare_access_ex>.

