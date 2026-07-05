{
  self,
  inputs,
  lib,
  zpkgs,
}:
self.modules.hosts
|> builtins.attrNames
|> (
  hosts:
  lib.genAttrs hosts (
    hostname:
    let
      system = self.modules.hosts.${hostname}.system or "x86_64-linux";
      channelOverlay = final: prev: {
        inherit stable master;
        inherit (prev.stdenv.hostPlatform) system;
      };
      stable = import inputs.stable {
        inherit system;
        config.allowUnfree = true;
      };
      master = import inputs.master {
        inherit system;
        config.allowUnfree = true;
      };
      basepkgs = import inputs.nixpkgs {
        inherit system zpkgs;
        config.allowUnfree = true;
        overlays = [
          inputs.nix-cachyos-kernel.overlays.pinned
          inputs.neovim-nightly.overlays.default
          channelOverlay
        ];
      };

      pkgs = basepkgs // {
        inherit stable master;
      };
    in
    inputs.finix.lib.finixSystem {
      inherit lib;
      modules = [
        {
          nixpkgs.pkgs = inputs.nixpkgs.lib.mkDefault pkgs;
        }
        self.modules.hosts.${hostname}
        inputs.community-modules.nixosModules.pipewire
        inputs.community-modules.nixosModules.laptop
      ]
      ++ (builtins.attrValues inputs.finix.nixosModules);
      specialArgs = {
        inherit
          zpkgs
          self
          inputs
          system
          ;
        modulesPath = toString inputs.nixpkgs + "/nixos/modules";
    inputs.nixpkgs.lib.nixosSystem {
      inherit lib;
      modules = [
        self.modules.hosts.${hostname}
        { nixpkgs.overlays = import ../../overlays { inherit inputs; }; }
      ];
      specialArgs = {
        inherit
          self
          inputs
          system
          zpkgs
          ;
      }
      // inputs;
    }
  )
)
|> (finix: { inherit finix; })

