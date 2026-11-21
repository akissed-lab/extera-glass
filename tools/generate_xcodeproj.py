#!/usr/bin/env python3
"""Генерирует ExteraGlass.xcodeproj (project.pbxproj) из списка исходников.

Нужен, чтобы не править pbxproj вручную: ID детерминированы, файлы
добавляются автоматически. Запуск: python tools/generate_xcodeproj.py
"""
from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TARGET = "ExteraGlass"
SWIFT_DIR = ROOT / TARGET


def oid(key: str) -> str:
    return hashlib.sha1(key.encode("utf-8")).hexdigest()[:24].upper()


def quote(value: str) -> str:
    return f'"{value}"'


def main() -> None:
    swift_files = sorted(p for p in SWIFT_DIR.rglob("*.swift") if p.is_file())
    rel = [p.relative_to(ROOT).as_posix() for p in swift_files]
    print(f"Исходников: {len(rel)}")

    L: list[str] = []
    add = L.append

    add("// !$*UTF8*$!")
    add("{")
    add("\tarchiveVersion = 1;")
    add("\tclasses = {")
    add("\t};")
    add("\tobjectVersion = 56;")
    add("\tobjects = {")

    # --- PBXBuildFile ---
    add("/* Begin PBXBuildFile section */")
    for path in rel:
        add(f"\t\t{oid('build:' + path)} /* {Path(path).name} in Sources */ = {{isa = PBXBuildFile; fileRef = {oid('file:' + path)} /* {Path(path).name} */; }};")
    assets = f"{TARGET}/Assets.xcassets"
    add(f"\t\t{oid('build:' + assets)} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {oid('file:' + assets)} /* Assets.xcassets */; }};")
    add("\t\t" + oid("build:tdlibkit") + " /* TDLibKit in Frameworks */ = {isa = PBXBuildFile; productRef = " + oid("product:tdlibkit") + " /* TDLibKit */; };")
    add("/* End PBXBuildFile section */")

    # --- PBXFileReference ---
    add("/* Begin PBXFileReference section */")
    for path in rel:
        add(f'\t\t{oid("file:" + path)} /* {Path(path).name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quote(Path(path).name)}; sourceTree = "<group>"; }};')
    add(f'\t\t{oid("file:" + assets)} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};')
    add(f'\t\t{oid("file:product")} /* {TARGET}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {TARGET}.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    add(f'\t\t{oid("file:Info.plist")} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};')
    add("/* End PBXFileReference section */")

    # --- PBXFrameworksBuildPhase ---
    add("/* Begin PBXFrameworksBuildPhase section */")
    add("\t\t" + oid("phase:frameworks") + " /* Frameworks */ = {")
    add("\t\t\tisa = PBXFrameworksBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    add("\t\t\t\t" + oid("build:tdlibkit") + " /* TDLibKit in Frameworks */,")
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add("/* End PBXFrameworksBuildPhase section */")

    # --- PBXGroup ---
    add("/* Begin PBXGroup section */")
    add("\t\t" + oid("group:root") + " = {")
    add("\t\t\tisa = PBXGroup;")
    add("\t\t\tchildren = (")
    add(f'\t\t\t\t{oid("group:app")} /* {TARGET} */,')
    add("\t\t\t\t" + oid("group:products") + " /* Products */,")
    add("\t\t\t);")
    add("\t\t\tsourceTree = \"<group>\";")
    add("\t\t};")
    add("\t\t" + oid("group:products") + " /* Products */ = {")
    add("\t\t\tisa = PBXGroup;")
    add("\t\t\tchildren = (")
    add(f'\t\t\t\t{oid("file:product")} /* {TARGET}.app */,')
    add("\t\t\t);")
    add("\t\t\tname = Products;")
    add("\t\t\tsourceTree = \"<group>\";")
    add("\t\t};")
    add(f'\t\t{oid("group:app")} /* {TARGET} */ = {{')
    add("\t\t\tisa = PBXGroup;")
    add("\t\t\tchildren = (")
    # группируем по подпапкам
    groups: dict[str, list[str]] = {}
    for path in rel:
        parent = str(Path(path).parent.relative_to(SWIFT_DIR.relative_to(ROOT)))
        groups.setdefault(parent, []).append(path)
    for parent in sorted(groups):
        if parent == ".":
            for path in groups[parent]:
                add(f'\t\t\t\t{oid("file:" + path)} /* {Path(path).name} */,')
        else:
            add(f'\t\t\t\t{oid("group:sub:" + parent)} /* {parent} */,')
    add(f'\t\t\t\t{oid("file:" + assets)} /* Assets.xcassets */,')
    add(f'\t\t\t\t{oid("file:Info.plist")} /* Info.plist */,')
    add("\t\t\t);")
    add(f'\t\t\tpath = {TARGET};')
    add("\t\t\tsourceTree = \"<group>\";")
    add("\t\t};")
    for parent, paths in groups.items():
        if parent == ".":
            continue
        gid = oid("group:sub:" + parent)
        add(f"\t\t{gid} /* {parent} */ = {{")
        add("\t\t\tisa = PBXGroup;")
        add("\t\t\tchildren = (")
        for path in sorted(paths):
            add(f'\t\t\t\t{oid("file:" + path)} /* {Path(path).name} */,')
        add("\t\t\t);")
        add(f'\t\t\tpath = {parent};')
        add("\t\t\tsourceTree = \"<group>\";")
        add("\t\t};")
    add("/* End PBXGroup section */")

    # --- PBXNativeTarget ---
    add("/* Begin PBXNativeTarget section */")
    target_id = oid("target:app")
    add(f"\t\t{target_id} /* {TARGET} */ = {{")
    add("\t\t\tisa = PBXNativeTarget;")
    add(f'\t\t\tbuildConfigurationList = {oid("conflist:target")} /* Build configuration list for PBXNativeTarget "{TARGET}" */;')
    add("\t\t\tbuildPhases = (")
    add("\t\t\t\t" + oid("phase:sources") + " /* Sources */,")
    add("\t\t\t\t" + oid("phase:frameworks") + " /* Frameworks */,")
    add("\t\t\t\t" + oid("phase:resources") + " /* Resources */,")
    add("\t\t\t);")
    add("\t\t\tbuildRules = (")
    add("\t\t\t);")
    add("\t\t\tdependencies = (")
    add("\t\t\t);")
    add(f'\t\t\tname = {TARGET};')
    add("\t\t\tpackageProductDependencies = (")
    add("\t\t\t\t" + oid("product:tdlibkit") + " /* TDLibKit */,")
    add("\t\t\t);")
    add(f'\t\t\tproductName = {TARGET};')
    add(f'\t\t\tproductReference = {oid("file:product")} /* {TARGET}.app */;')
    add('\t\t\tproductType = "com.apple.product-type.application";')
    add("\t\t};")
    add("/* End PBXNativeTarget section */")

    # --- PBXProject ---
    add("/* Begin PBXProject section */")
    add("\t\t" + oid("project") + " /* Project object */ = {")
    add("\t\t\tisa = PBXProject;")
    add("\t\t\tattributes = {")
    add("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    add("\t\t\t\tLastUpgradeCheck = 2600;")
    add("\t\t\t\tTargetAttributes = {")
    add(f"\t\t\t\t\t{target_id} = {{")
    add('\t\t\t\t\t\tCreatedOnToolsVersion = "16.0";')
    add("\t\t\t\t\t};")
    add("\t\t\t\t};")
    add("\t\t\t};")
    add(f'\t\t\tbuildConfigurationList = {oid("conflist:project")} /* Build configuration list for PBXProject "{TARGET}" */;')
    add('\t\t\tcompatibilityVersion = "Xcode 14.0";')
    add("\t\t\tdevelopmentRegion = en;")
    add("\t\t\thasScannedForEncodings = 0;")
    add("\t\t\tknownRegions = (")
    add("\t\t\t\ten,")
    add("\t\t\t\tBase,")
    add("\t\t\t);")
    add("\t\t\tmainGroup = " + oid("group:root") + ";")
    add("\t\t\tpackageReferences = (")
    add("\t\t\t\t" + oid("package:tdlibkit") + " /* XCRemoteSwiftPackageReference \"TDLibKit\" */,")
    add("\t\t\t);")
    add('\t\t\tproductRefGroup = ' + oid("group:products") + ' /* Products */;')
    add('\t\t\tprojectDirPath = "";')
    add('\t\t\tprojectRoot = "";')
    add("\t\t\ttargets = (")
    add(f"\t\t\t\t{target_id} /* {TARGET} */,")
    add("\t\t\t);")
    add("\t\t};")
    add("/* End PBXProject section */")

    # --- PBXResourcesBuildPhase ---
    add("/* Begin PBXResourcesBuildPhase section */")
    add("\t\t" + oid("phase:resources") + " /* Resources */ = {")
    add("\t\t\tisa = PBXResourcesBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    add("\t\t\t\t" + oid("build:" + assets) + " /* Assets.xcassets in Resources */,")
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add("/* End PBXResourcesBuildPhase section */")

    # --- PBXSourcesBuildPhase ---
    add("/* Begin PBXSourcesBuildPhase section */")
    add("\t\t" + oid("phase:sources") + " /* Sources */ = {")
    add("\t\t\tisa = PBXSourcesBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    for path in rel:
        add(f"\t\t\t\t{oid('build:' + path)} /* {Path(path).name} in Sources */,")
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add("/* End PBXSourcesBuildPhase section */")

    # --- XCBuildConfiguration project ---
    common = [
        ("ALWAYS_SEARCH_USER_PATHS", "NO"),
        ("CLANG_ENABLE_MODULES", "YES"),
        ("CLANG_ENABLE_OBJC_ARC", "YES"),
        ("ENABLE_STRICT_OBJC_MSGSEND", "YES"),
        ("GCC_C_LANGUAGE_STANDARD", "gnu17"),
        ("IPHONEOS_DEPLOYMENT_TARGET", "17.0"),
        ("SDKROOT", "iphoneos"),
        ("SWIFT_VERSION", "5.0"),
        ("SWIFT_STRICT_CONCURRENCY", "minimal"),
    ]
    for cfg in ("Debug", "Release"):
        cid = oid(f"config:project:{cfg}")
        add(f"\t\t{cid} /* {cfg} */ = {{")
        add("\t\t\tisa = XCBuildConfiguration;")
        add("\t\t\tbuildSettings = {")
        for k, v in common:
            add(f"\t\t\t\t{k} = {v};")
        if cfg == "Debug":
            add("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
            add("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
            add("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
            add("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
        else:
            add("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
            add("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";")
            add("\t\t\t\tVALIDATE_PRODUCT = YES;")
        add("\t\t\t};")
        add(f"\t\t\tname = {cfg};")
        add("\t\t};")

    # --- XCBuildConfiguration target ---
    for cfg in ("Debug", "Release"):
        cid = oid(f"config:target:{cfg}")
        add(f"\t\t{cid} /* {cfg} */ = {{")
        add("\t\t\tisa = XCBuildConfiguration;")
        add("\t\t\tbuildSettings = {")
        add("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
        add("\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;")
        add('\t\t\t\tCODE_SIGN_STYLE = Automatic;')
        add('\t\t\t\tCURRENT_PROJECT_VERSION = 1;')
        add(f'\t\t\t\tINFOPLIST_FILE = {TARGET}/Info.plist;')
        add('\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (')
        add('\t\t\t\t\t"$(inherited)",')
        add('\t\t\t\t\t"@executable_path/Frameworks",')
        add('\t\t\t\t);')
        add(f'\t\t\t\tMARKETING_VERSION = 1.0.0;')
        add(f'\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = app.exteraglass.client;')
        add(f'\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
        add('\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";')
        add('\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;')
        add('\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";')
        add('\t\t\t\tGENERATE_INFOPLIST_FILE = NO;')
        add('\t\t\t\tENABLE_PREVIEWS = YES;')
        if cfg == "Debug":
            add('\t\t\t\tCODE_SIGNING_ALLOWED = YES;')
        add("\t\t\t};")
        add(f"\t\t\tname = {cfg};")
        add("\t\t};")

    # --- XCConfigurationList ---
    for key, name in (("project", "PBXProject"), ("target", f'PBXNativeTarget "{TARGET}"')):
        add(f"\t\t{oid('conflist:' + key)} /* Build configuration list for {name} */ = {{")
        add("\t\t\tisa = XCConfigurationList;")
        add("\t\t\tbuildConfigurations = (")
        for cfg in ("Debug", "Release"):
            add(f"\t\t\t\t{oid(f'config:{key}:{cfg}')} /* {cfg} */,")
        add("\t\t\t);")
        add("\t\t\tdefaultConfigurationIsVisible = 0;")
        add('\t\t\tdefaultConfigurationName = Release;')
        add("\t\t};")

    # --- XCRemoteSwiftPackageReference ---
    add("/* Begin XCRemoteSwiftPackageReference section */")
    add("\t\t" + oid("package:tdlibkit") + ' /* XCRemoteSwiftPackageReference "TDLibKit" */ = {')
    add("\t\t\tisa = XCRemoteSwiftPackageReference;")
    add('\t\t\trepositoryURL = "https://github.com/Swiftgram/TDLibKit.git";')
    add("\t\t\trequirement = {")
    add('\t\t\t\tbranch = master;')
    add('\t\t\t\tkind = branch;')
    add("\t\t\t};")
    add("\t\t};")
    add("/* End XCRemoteSwiftPackageReference section */")

    # --- XCSwiftPackageProductDependency ---
    add("/* Begin XCSwiftPackageProductDependency section */")
    add("\t\t" + oid("product:tdlibkit") + ' /* TDLibKit */ = {')
    add("\t\t\tisa = XCSwiftPackageProductDependency;")
    add("\t\t\tpackage = " + oid("package:tdlibkit") + ' /* XCRemoteSwiftPackageReference "TDLibKit" */;')
    add('\t\t\tproductName = TDLibKit;')
    add("\t\t};")
    add("/* End XCSwiftPackageProductDependency section */")

    add("\t};")
    add(f"\trootObject = {oid('project')} /* Project object */;")
    add("}")

    out = ROOT / f"{TARGET}.xcodeproj" / "project.pbxproj"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(L) + "\n", encoding="utf-8")
    print(f"Готово: {out}")


if __name__ == "__main__":
    main()
