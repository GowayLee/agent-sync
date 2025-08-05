(lang dune 3.19)

(name agent-sync)

(generate_opam_files true)

(source
 (github gowaylee/agent-sync))

(authors "Haoyuan Li lihaoyuan0506@gmail.com")

(maintainers "Haoyuan Li lihaoyuan0506@gmail.com")

(license GPL-3.0-only)

(documentation https://github.com/GowayLee/agent-sync/blob/main/README.md )

(package
 (name agent-sync)
 (synopsis "A cli tool to sync different markdown files for code agents")
 (description "A cli tool to sync different markdown files for code agents")
 (depends ocaml
          toml
          cmdliner
          yojson
          ounit2
          )
 (tags
  ("Code agent" "Cli")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
