{ lib
, stdenv
, cmake
, ninja
, perl
, srcs
, patches ? [ ]
}:

args:

let
  inherit (args) pname;
  version = args.version or srcs.${pname}.version;
  src = args.src or srcs.${pname}.src;
in
stdenv.mkDerivation (args // {
  inherit pname version src;
  patches = args.patches or patches.${pname} or [ ];

  preHook = ''
    . ${./hooks/move-qt-dev-tools.sh}
  '';

  buildInputs = args.buildInputs or [ ];
  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [ cmake ninja perl ];
  propagatedBuildInputs = args.qtInputs ++ (args.propagatedBuildInputs or [ ]);

  outputs = args.outputs or [ "out" "dev" ];

  dontWrapQtApps = args.dontWrapQtApps or true;

  postFixup = ''
    moveToOutput "libexec" "''${!outputDev}"
    moveQtDevTools
  '' + args.postFixup or "";

  meta = with lib; {
    homepage = "https://www.qt.io/";
    description = "A cross-platform application framework for C++";
    license = with licenses; [ fdl13Plus gpl2Plus lgpl21Plus lgpl3Plus ];
    maintainers = with maintainers; [ milahu nickcao ];
    platforms = platforms.unix;
  } // (args.meta or { });
})
