{
  description = "langfuse";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};

      inherit (pkgs.stdenv) isDarwin isLinux;
      inherit (pkgs.lib) optionals;

      # --- Base toolchain shared by all systems (no Rust) ---
      baseDeps = with pkgs; [
        beam.packages.erlang_28.elixir_1_18
        gcc13
        entr
        # For Claude CLI & formatting
        nodejs_24
        bun
      ];

      common = baseDeps;

      # Extra developer conveniences when not in CI
      devExtra =
        if builtins.getEnv "CI" != "true"
        then
          with pkgs; [
            nixpkgs-fmt
            fswatch
            # Linting / formatting
            shfmt
            nodePackages.prettier
          ]
        else [];

      all = common ++ devExtra;

      inherit (pkgs) inotify-tools terminal-notifier;

      linuxDeps = optionals isLinux [inotify-tools];
      darwinDeps = optionals isDarwin [terminal-notifier];
    in {
      devShells.default = pkgs.mkShell {
        packages = all ++ linuxDeps ++ darwinDeps;

        shellHook = ''
          # --- Isolate Mix/Hex ---
          mkdir -p .nix-mix .nix-hex
          export MIX_HOME=$PWD/.nix-mix
          export HEX_HOME=$PWD/.nix-hex
          export MIX_PATH="${pkgs.beam.packages.erlang_28.hex}/lib/erlang/lib/hex/ebin"

          # --- Node local binaries ---
          export PATH=$PWD/node_modules/.bin:$PWD/bin:$PATH

          # Prepend language toolchains to PATH (Elixir only)
          export PATH=${pkgs.erlang_28}/bin:$MIX_HOME/bin:$HEX_HOME/bin:$MIX_HOME/escripts:$PATH

          export LANG=C.UTF-8
          export ERL_AFLAGS="-kernel shell_history enabled"
          export MIX_ENV=dev

          # Install JS deps (Claude CLI etc.) locally via Bun
          bun install --silent || true
          claude --version || true
        '';
      };
    });
}
