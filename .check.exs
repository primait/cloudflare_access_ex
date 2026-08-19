[
  tools: [
    {:compiler, env: %{"MIX_ENV" => "test"}},
    {:formatter, env: %{"MIX_ENV" => "test"}},
    {:ex_doc, env: %{"MIX_ENV" => "test"}},
    {:mix_audit, "mix deps.audit --ignore-package-names hackney"}
  ]
]
