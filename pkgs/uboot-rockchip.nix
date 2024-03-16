{ pkgs, stdenv, lib, fetchpatch, fetchFromGitHub, buildUBoot, buildPackages }:

let
  buildPatchedUBoot = { defconfig, BL31, ROCKCHIP_TPL ? "" }:
    let
      inherit defconfig BL31 ROCKCHIP_TPL;
      src = fetchFromGitHub {
        owner = "u-boot";
        repo = "u-boot";
        rev = "v2023.10";
        sha256 = "f0xDGxTatRtCxwuDnmsqFLtYLIyjA5xzyQcwfOy3zEM=";
      };
      version = "v2023.10-69-g0bc339ffa6"; # git describe --long
    in buildUBoot {
      src = src;
      version = version;
      defconfig = defconfig;
      filesToInstall = [ "u-boot-rockchip.bin" ];

      patches = [
        (fetchpatch {
          name = "quartz64.patch";
          url =
            "https://github.com/Kwiboo/u-boot-rockchip/compare/4459ed60cb1e0562bc5b40405e2b4b9bbf766d57...0bc339ffa6f804d51c5c5292d8ff69c4d79614d3.diff";
          sha256 = "ui77Nm3IS6PUzaMagqyyZDitklot8MmeYg27mVPV7Pc=";
        })
        ./ramdisk_addr_r.patch
      ];

      buildInputs = with buildPackages; [
        ncurses # tools/kwboot
        libuuid # tools/mkeficapsule
        gnutls # tools/mkeficapsule
        openssl # tools/imagetool
      ];

      nativeBuildInputs = with buildPackages; [
        ncurses # tools/kwboot
        bc
        bison
        dtc
        flex
        openssl
        (python3.withPackages (p: [
          p.libfdt
          p.setuptools # for pkg_resources
          p.pyelftools
        ]))
        swig
        which # for scripts/dtc-version.sh
      ];

      makeFlags = [ "CROSS_COMPILE=${stdenv.cc.targetPrefix}" ];

      BL31 = BL31;
      ROCKCHIP_TPL = ROCKCHIP_TPL;

      extraMeta = {
        platforms = [ "aarch64-linux" ];
        license = lib.licenses.unfreeRedistributableFirmware;
      };
    };
  buildRK3328UBoot = defconfig:
    buildPatchedUBoot {
      inherit defconfig;
      BL31 = "${pkgs.armTrustedFirmwareRK3328}/bl31.elf";
    };
  buildRK3399UBoot = defconfig:
    buildPatchedUBoot {
      inherit defconfig;
      BL31 = "${pkgs.armTrustedFirmwareRK3399}/bl31.elf";
    };
  buildRK3566UBoot = defconfig:
    let
      rkbin = fetchFromGitHub {
        owner = "rockchip-linux";
        repo = "rkbin";
        rev = "b4558da0860ca48bf1a571dd33ccba580b9abe23";
        sha256 = "KUZQaQ+IZ0OynawlYGW99QGAOmOrGt2CZidI3NTxFw8=";
      };
    in buildPatchedUBoot {
      inherit defconfig;
      BL31 = (rkbin + "/bin/rk35/rk3568_bl31_v1.43.elf");
      ROCKCHIP_TPL = (rkbin + "/bin/rk35/rk3566_ddr_1056MHz_v1.18.bin");
    };
in {
  uBootQuartz64A = buildRK3566UBoot "quartz64-a-rk3566_defconfig";
  uBootQuartz64B = buildRK3566UBoot "quartz64-b-rk3566_defconfig";
  uBootSoQuartzBlade = buildRK3566UBoot "soquartz-blade-rk3566_defconfig";
  uBootSoQuartzCM4IO = buildRK3566UBoot "soquartz-cm4-rk3566_defconfig";
  uBootSoQuartzModelA = buildRK3566UBoot "soquartz-model-a-rk3566_defconfig";
  uBootPineTab2 = buildRK3566UBoot "pinetab2-rk3566_defconfig";
  uBootPinebookPro = buildRK3399UBoot "pinebook-pro-rk3399_defconfig";
  uBootRockPro64 = buildRK3399UBoot "rockpro64-rk3399_defconfig";
  uBootROCPCRK3399 = buildRK3399UBoot "roc-pc-rk3399_defconfig";
  uBootRock64 = buildRK3328UBoot "rock64-rk3328_defconfig";
  uBootOrangePiCM4 = buildRK3566UBoot "orangepi-3b-rk3566_defconfig";
}
