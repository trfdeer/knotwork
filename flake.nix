{
  description = "Knotwork - progress tracking";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      version = "1.1.0";

      build =
        pname:
        pkgs.buildGoModule {
          inherit pname version;
          src = self;
          subPackages = [ "./cmd/${pname}" ];
          vendorHash = "sha256-+0AXJHdW6G9nwHdM2gB3L5TO8XcKkb28v4IOIxah/wg=";
        };

      cli = build "knotwork-cli";
      mcp = build "knotwork-mcp";

      nfpmConfig = pkgs.writeText "nfpm.yaml" ''
        name: knotwork
        arch: amd64
        platform: linux
        version: ${version}

        contents:
          - src: ${cli}/bin/knotwork-cli
            dst: /usr/bin/knotwork-cli
          - src: ${mcp}/bin/knotwork-mcp
            dst: /usr/bin/knotwork-mcp
      '';

      pkg =
        format:
        pkgs.stdenvNoCC.mkDerivation {
          pname = "knotwork-${format}";
          inherit version;

          nativeBuildInputs = [ pkgs.nfpm ];
          dontUnpack = true;

          buildPhase = ''
            nfpm package \
              --config ${nfpmConfig} \
              --packager ${format} \
              --target knotwork.${format}
          '';

          installPhase = ''
            mkdir -p $out
            cp knotwork.${format} $out/
          '';
        };
    in
    {
      packages.${system} = {
        cli = cli;
        mcp = mcp;
        default = cli;

        deb = pkg "deb";
        rpm = pkg "rpm";
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [ go ];
        packages = with pkgs; [
          nixd
          nixfmt
          gopls
          go-tools
          golangci-lint
        ];
      };
    };
}
