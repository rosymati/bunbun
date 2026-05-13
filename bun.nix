{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  unzip,
  installShellFiles,
  makeWrapper,
  openssl,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  version = lib.trim (builtins.readFile ./VERSION);
  pname = "bun";

  src =
    finalAttrs.passthru.sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  strictDeps = true;

  nativeBuildInputs = [
    unzip
    installShellFiles
    makeWrapper
    autoPatchelfHook
  ];

  buildInputs = [ openssl ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm 755 ./bun $out/bin/bun
    ln -s $out/bin/bun $out/bin/bunx
    runHook postInstall
  '';

  postPhases = [ "postPatchelf" ];

  postPatchelf = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
    installShellCompletion --cmd bun \
      --bash <(SHELL="bash" $out/bin/bun completions) \
      --zsh  <(SHELL="zsh"  $out/bin/bun completions) \
      --fish <(SHELL="fish" $out/bin/bun completions)
  '';

  passthru.sources = {
    "aarch64-linux" = fetchurl {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v${finalAttrs.version}/bun-linux-aarch64.zip";
      hash = "sha256-on/7Y6gxA3WDbg1vZorhf6jY0YuIw3yCHGUzGXOhmjs=";
    };
    "x86_64-linux" = fetchurl {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v${finalAttrs.version}/bun-linux-x64.zip";
      hash = "sha256-lR7iruhV8IWVruxiJSJqKY0/6oOj3NZGXAnLzN9+hI8=";
    };
  };

  meta = {
    homepage = "https://bun.sh";
    changelog = "https://bun.sh/blog/bun-v${finalAttrs.version}";
    description = "Incredibly fast JavaScript runtime, bundler, transpiler and package manager – all in one";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    longDescription = ''
      All in one fast & easy-to-use tool. Instead of 1,000 node_modules for development, you only need bun.
    '';
    license = with lib.licenses; [
      mit
      lgpl21Only
    ];
    mainProgram = "bun";
    platforms = builtins.attrNames finalAttrs.passthru.sources;
    broken = stdenvNoCC.hostPlatform.isMusl;
  };
})
