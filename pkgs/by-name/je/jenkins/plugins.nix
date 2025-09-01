{ lib, fetchurl, ... }:
rec {
  pluginMap = builtins.concatMap (plugin: [ plugin ] ++ pluginMap plugin.dependencies);
  plugins = builtins.mapAttrs (
    name: info:
    fetchurl {
      inherit name;
      inherit (info) url version sha256;
      passthru = {
        dependencies = builtins.map (p: builtins.getAttr p plugins) info.dependencies;
      };
    }
  ) (lib.importJSON ./plugins.json);
  withPlugins =
    plugins:
    builtins.listToAttrs (
      builtins.map (p: {
        inherit (p) name;
        value = p;
      }) (pluginMap plugins)
    );
}
