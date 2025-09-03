{
  lib,
  linkFarm,
  fetchurl,
  curl,
  jq,
  openjdk21,
  jenkins,
  runCommand,
  ...
}:
rec {
  reapply =
    f: val:
    let
      next = f val;
    in
    if next == val then val else reapply f next;
  resolveDeps = plugins: lib.unique (plugins ++ builtins.concatMap (p: p.dependencies) plugins);
  pluginMap = reapply resolveDeps;
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
  pluginDir =
    plugins:
    linkFarm "plugins" (
      builtins.map (p: {
        name = "${p.pname}.jpi";
        path = builtins.toString p;
      }) (pluginMap plugins)
    );
  jcascSchema =
    pp:
    runCommand "schema.yaml" { } ''
      mkdir -p .jenkins/plugins
      cp -r ${pluginDir pp}/* .jenkins/plugins/
      ls -l .jenkins/plugins/
      ${lib.getExe openjdk21} -Djava.awt.headless=true -Djenkins.install.runSetupWizard=false -jar ${jenkins}/webapps/jenkins.war &
      while ! ${lib.getExe curl} -s http://localhost:8080/configuration-as-code/schema | ${lib.getExe jq} . > $out; do sleep 1; done
      kill $!
    '';
}
