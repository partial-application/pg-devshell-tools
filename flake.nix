{
  description = "A flake providing PostgreSQL tools for devShells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        postgresTools = [
          # Required when using nix on non-NixOS linux distro
          pkgs.glibcLocales
          (pkgs.writeShellScriptBin "pg-setup" ''
            if ! test -d $PGDATA; then
              initdb -D $PGDATA --encoding=UTF8 --locale=en_US.UTF-8
              echo 'Signature: 8a477f597d28d172789f06886806bc55' > $PGDATA/CACHEDIR.TAG
            fi
          '')
          (pkgs.writeShellScriptBin "pg-start" ''
            [ ! -d $PGDATA ] && pg-setup
            pg_ctl \
              -D $PGDATA \
              -l $PGDATA/postgres.log \
              -o "-k $PGDATA -c listen_addresses=" \
              start
            [ $(psql -XtAc "SELECT 1 FROM pg_database WHERE datname='"$PGDATABASE"'" postgres) ] || createdb $PGDATABASE
          '')
          (pkgs.writeShellScriptBin "pg-stop" ''
            pg_ctl -D $PGDATA stop
          '')
          (pkgs.writeShellScriptBin "pg-reset" ''
            pg-stop; rm -rf $PGDATA
          '')
        ];
      in
      {
        packages.default = pkgs.buildEnv {
          name = "pg-devshell-tools";
          paths = postgresTools;
        };
      }
    );
}
