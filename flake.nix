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

      # Create run script package
      runScript = pkgs.writeShellScriptBin "run" ''
        #!/usr/bin/env bash

        set -euo pipefail

        # Change to the directory containing this script
        cd "$(dirname "$0")/../.."

        # Colors for output
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        NC='\033[0m' # No Color

        # Print usage information
        usage() {
            echo -e "''${BLUE}Usage: run <command>''${NC}"
            echo ""
            echo -e "''${YELLOW}Available commands:''${NC}"
            echo "  test              Run all tests"
            echo "  test.watch        Run tests in watch mode"
            echo "  lint              Run credo linter"
            echo "  format            Format code with mix format"
            echo "  format.check      Check if code is formatted"
            echo "  format.all        Format all code (Elixir, shell, nix, JS/JSON)"
            echo "  format.all.check  Check if all code is formatted"
            echo "  deps              Install dependencies"
            echo "  deps.update       Update dependencies"
            echo "  docs              Generate documentation"
            echo "  spec.sync         Download latest OpenAPI spec"
            echo "  api.gen           Generate API client from OpenAPI spec"
            echo "  sdk.build         Full SDK rebuild (spec.sync + api.gen)"
            echo "  help              Show this help message"
            echo ""
            echo -e "''${YELLOW}Examples:''${NC}"
            echo "  run test"
            echo "  run format"
            echo "  run lint"
        }

        # Helper function to run mix commands
        run_mix() {
            echo -e "''${BLUE}Running: mix $*''${NC}"
            mix "$@"
        }

        # Helper function to check if dependencies are installed
        check_deps() {
            if [ ! -d "deps" ] || [ ! -f "mix.lock" ]; then
                echo -e "''${YELLOW}Dependencies not found. Installing...''${NC}"
                run_mix deps.get
            fi
        }

        # Main command handling
        case "''${1:-help}" in
            test)
                check_deps
                echo -e "''${GREEN}Running tests...''${NC}"
                run_mix test
                ;;
            
            test.watch)
                check_deps
                echo -e "''${GREEN}Running tests in watch mode...''${NC}"
                run_mix test --stale --listen-on-stdin
                ;;
            
            lint)
                check_deps
                echo -e "''${GREEN}Running linter...''${NC}"
                if mix help credo >/dev/null 2>&1; then
                    run_mix credo --strict
                else
                    echo -e "''${YELLOW}Credo not available. Install with: mix deps.get''${NC}"
                    exit 1
                fi
                ;;
            
            format)
                echo -e "''${GREEN}Formatting code...''${NC}"
                run_mix format
                echo -e "''${GREEN}Code formatted successfully!''${NC}"
                ;;
            
            format.check)
                echo -e "''${GREEN}Checking code format...''${NC}"
                if run_mix format --check-formatted; then
                    echo -e "''${GREEN}Code is properly formatted!''${NC}"
                else
                    echo -e "''${RED}Code is not properly formatted. Run: run format''${NC}"
                    exit 1
                fi
                ;;
            
            deps)
                echo -e "''${GREEN}Installing dependencies...''${NC}"
                run_mix deps.get
                ;;
            
            deps.update)
                echo -e "''${GREEN}Updating dependencies...''${NC}"
                run_mix deps.update --all
                ;;
            
            docs)
                check_deps
                echo -e "''${GREEN}Generating documentation...''${NC}"
                run_mix docs
                echo -e "''${GREEN}Documentation generated in doc/''${NC}"
                ;;
            
            spec.sync)
                echo -e "''${GREEN}Downloading latest OpenAPI spec...''${NC}"
                run_mix spec.sync
                echo -e "''${GREEN}OpenAPI spec updated!''${NC}"
                ;;
            
            api.gen)
                echo -e "''${GREEN}Generating API client from OpenAPI spec...''${NC}"
                run_mix api.gen default openapi.yml
                echo -e "''${GREEN}API client generated!''${NC}"
                ;;
            
            sdk.build)
                echo -e "''${GREEN}Rebuilding SDK from latest spec...''${NC}"
                run_mix sdk.build
                echo -e "''${GREEN}SDK rebuilt successfully!''${NC}"
                ;;
            
            format.all)
                echo -e "''${GREEN}Formatting all code...''${NC}"
                echo -e "''${BLUE}Formatting Elixir code...''${NC}"
                run_mix format
                echo -e "''${BLUE}Formatting shell scripts...''${NC}"
                find . -name "*.sh" -o -path "./bin/*" -type f | xargs shfmt -w -i 4 -ci
                echo -e "''${BLUE}Formatting Nix files...''${NC}"
                find . -name "*.nix" | xargs nixpkgs-fmt
                echo -e "''${BLUE}Formatting JS/JSON files...''${NC}"
                prettier --write "**/*.{js,json,md,yml,yaml}"
                echo -e "''${GREEN}All code formatted successfully!''${NC}"
                ;;
            
            format.all.check)
                echo -e "''${GREEN}Checking all code format...''${NC}"
                format_errors=0
                
                echo -e "''${BLUE}Checking Elixir format...''${NC}"
                if ! run_mix format --check-formatted; then
                    echo -e "''${RED}Elixir code is not properly formatted''${NC}"
                    format_errors=$((format_errors + 1))
                fi
                
                echo -e "''${BLUE}Checking shell script format...''${NC}"
                if ! find . -name "*.sh" -o -path "./bin/*" -type f | xargs shfmt -d -i 4 -ci; then
                    echo -e "''${RED}Shell scripts are not properly formatted''${NC}"
                    format_errors=$((format_errors + 1))
                fi
                
                echo -e "''${BLUE}Checking Nix file format...''${NC}"
                if ! find . -name "*.nix" | xargs nixpkgs-fmt --check; then
                    echo -e "''${RED}Nix files are not properly formatted''${NC}"
                    format_errors=$((format_errors + 1))
                fi
                
                echo -e "''${BLUE}Checking JS/JSON format...''${NC}"
                if ! prettier --check "**/*.{js,json,md,yml,yaml}"; then
                    echo -e "''${RED}JS/JSON files are not properly formatted''${NC}"
                    format_errors=$((format_errors + 1))
                fi
                
                if [ $format_errors -eq 0 ]; then
                    echo -e "''${GREEN}All code is properly formatted!''${NC}"
                else
                    echo -e "''${RED}$format_errors format issue(s) found. Run: run format.all''${NC}"
                    exit 1
                fi
                ;;
            
            help|--help|-h)
                usage
                ;;
            
            *)
                echo -e "''${RED}Unknown command: $1''${NC}"
                echo ""
                usage
                exit 1
                ;;
        esac
      '';

      linuxDeps = optionals isLinux [inotify-tools];
      darwinDeps = optionals isDarwin [terminal-notifier];
    in {
      packages.default = runScript;
      packages.run = runScript;

      devShells.default = pkgs.mkShell {
        packages = all ++ linuxDeps ++ darwinDeps ++ [runScript];

        shellHook = ''
          # --- Isolate Mix/Hex ---
          mkdir -p .nix-mix .nix-hex
          export MIX_HOME=$PWD/.nix-mix
          export HEX_HOME=$PWD/.nix-hex
          export MIX_PATH="${pkgs.beam.packages.erlang_28.hex}/lib/erlang/lib/hex/ebin"

          # --- Node local binaries ---
          export PATH=$PWD/node_modules/.bin:$PATH

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
