{
  inputs.jsonresume-nix.url = "github:TaserudConsulting/jsonresume-nix";
  inputs.jsonresume-nix.inputs.flake-utils.follows = "flake-utils";
  inputs.flake-utils.url = "flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    jsonresume-nix,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
    in {
      # nix fmt .
      # nix fmt . -- --check
      formatter = pkgs.alejandra;

      # To show available packaged themes:
      #   nix flake show github:TaserudConsulting/jsonresume-nix
      packages = {
        inherit (jsonresume-nix.packages.${system}) nix-to-json;
        builder = jsonresume-nix.packages.${system}.resumed-fullmoon;
        #builder = jsonresume-nix.packages.${system}.resumed-elegant; # broken?
        #builder = jsonresume-nix.packages.${system}.resumed-kendall;
        #builder = jsonresume-nix.packages.${system}.resumed-macchiato;
        #builder = jsonresume-nix.packages.${system}.resumed-stackoverflow;
        default = pkgs.runCommand "resume" {} ''
          ln -s ${./resume.toml} resume.toml
          ls
          ${self.packages.${system}.builder}
          mkdir $out
          cp -v resume.html $out/index.html
          cp -v ${./me.jpg} $out/me.jpg
        '';
      };

      apps = {
        live.type = "app";
        live.program = builtins.toString (
          pkgs.writeShellScript "entr-reload" ''
            ${self.packages.${system}.builder}
            ${lib.getExe pkgs.nodePackages.live-server} \
              --watch=resume.html --open=resume.html --wait=300 &
            printf "\n%s" resume.{toml,nix,json} |
              ${lib.getExe pkgs.xe} -s 'test -f "$1" && echo "$1"' |
              ${lib.getExe pkgs.entr} -p ${self.packages.${system}.builder}
          ''
        );
      };
    })
    // {
      inherit inputs;
    };
}
