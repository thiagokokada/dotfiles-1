{
  description = "NixOS configuration with flakes";

  # To update all inputs:
  # $ nix flake update --recreate-lock-file
  inputs = {
    nixpkgs.url = github:Mic92/nixpkgs/master;
    # for development
    #nixpkgs.url = "/home/joerg/git/nixpkgs";
    nur.url = github:nix-community/NUR;
    sops-nix.url = github:Mic92/sops-nix;
    krops.url = github:krebs/krops;
    krops.flake = false;
    retiolum.url = git+https://git.thalheim.io/Mic92/retiolum;
    # for development
    #sops-nix.url = "/home/joerg/git/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = github:Mic92/nixos-hardware/master;
    home-manager.url = github:rycee/home-manager;
    home-manager.flake = false;

    choose-place.url = github:mbailleu/choose-place;
    choose-place.flake = false;

    doom-emacs.url = github:hlissner/doom-emacs;
    doom-emacs.flake = false;

    nix-doom-emacs.url = github:vlaci/nix-doom-emacs;
    nix-doom-emacs.flake = false;
  };

  outputs = { self
            , nixpkgs
            , nixos-hardware
            , sops-nix
            , nur
            , home-manager
            , choose-place
            , retiolum
            , ... }:
    let
      defaultModules = [
        {
          nix.nixPath = [
            "home-manager=${home-manager}"
            "nixpkgs=${nixpkgs}"
            "nur=${nur}"
          ];
          nixpkgs.overlays = [ nur.overlay ];
          #system.nixos.versionSuffix = "";
        }
        retiolum.nixosModules.retiolum
        sops-nix.nixosModules.sops
      ];
    in {
      nixosConfigurations.turingmachine = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = defaultModules ++ [
          nixos-hardware.nixosModules.dell-xps-13-9380
          ./nixos/turingmachine/configuration.nix
        ];
      };
      nixosConfigurations.eddie = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = defaultModules ++ [ ./nixos/eddie/configuration.nix ];
      };
      nixosConfigurations.eve = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = defaultModules ++ [
          ./nixos/eve/configuration.nix
          {
            nixpkgs.overlays = [(self: super: {
              choose-place = super.callPackage "${choose-place}" {};
            })];
          }
        ];
      };

      hmConfigurations = let
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
        extendedLib = import "${home-manager}/modules/lib/stdlib-extended.nix" pkgs.lib;
        buildHomeManager = configuration: rec {
          hmModules = import "${home-manager}/modules/modules.nix" {
            inherit pkgs;
            lib = extendedLib;
            useNixpkgsModule = true;
          };
          module = extendedLib.evalModules {
            modules = [
              {
                nixpkgs.config.packageOverrides = pkgs: {
                  nur = import "${nur}" {
                    inherit pkgs;
                  };
                };
              }
              configuration
            ] ++ hmModules;
          };
          activate = pkgs.writeShellScript "home-manager-activate" ''
            #!${pkgs.runtimeShell}
            exec ${module.config.home.activationPackage}/activate
          '';
        };
      in rec {
        common = buildHomeManager "${self}/nixpkgs-config/common.nix";
        desktop = buildHomeManager "${self}/nixpkgs-config/desktop.nix";
      };

      inherit (nixpkgs) legacyPackages;

      hydraJobs = {
        configurations = nixpkgs.lib.mapAttrs' (name: config:
          nixpkgs.lib.nameValuePair name config.config.system.build.toplevel)
          self.nixosConfigurations;
        hmConfigurations = nixpkgs.lib.mapAttrs' (name: config:
          nixpkgs.lib.nameValuePair name config.activate)
          self.hmConfigurations;
      };
    };
}
