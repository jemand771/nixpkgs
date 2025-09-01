{ lib, fetchurl, ... }:
rec {
  pluginMap = builtins.concatMap (plugin: [ plugin ] ++ pluginMap plugin.dependencies);
  plugins = builtins.mapAttrs (
    pname: info:
    fetchurl {
      inherit pname;
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
        name = p.pname;
        value = p;
      }) (pluginMap plugins)
    );
}
