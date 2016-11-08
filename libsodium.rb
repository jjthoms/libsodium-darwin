#!/usr/bin/env ruby

#
# A Ruby script to download and build libsodium for iOS, macOS, tvOS and watchOS
# Adapted from https://github.com/drewcrawford/libsodium-ios/blob/master/libsodium.sh
#

require 'fileutils'

if /darwin/ !~ RUBY_PLATFORM
  puts "This script needs macOS to run"
  exit 1
end

#
# libsodium release version
# Please visit https://github.com/jedisct1/libsodium/releases
#

# Download and extract the latest stable release indicated by PKG_VER variable
def download_and_extract_libsodium()
  puts "Downloading latest stable release of 'libsodium'"
  libsodium_dir = "build/libsodium"
  pkg_name      = "libsodium-#{PKG_VER}"
  pkg           = "#{pkg_name}.tar.gz"
  url           = "https://github.com/jedisct1/libsodium/releases/download/#{PKG_VER}/#{pkg}"
  exit 1 unless system("curl -O -L #{url}")
  exit 1 unless system("tar xzf #{pkg}")
  FileUtils.mv pkg_name, libsodium_dir
end

def find_sdks
  sdks=`xcodebuild -showsdks`.chomp
  sdk_versions = {}
  for line in sdks.lines do
    if line =~ /-sdk iphoneos(\S+)/
      sdk_versions["iOS"]     = $1
    elsif line =~ /-sdk macosx(\S+)/
      sdk_versions["macOS"]   = $1
    elsif line =~ /-sdk appletvos(\S+)/
      sdk_versions["tvOS"]    = $1
    elsif line =~ /-sdk watchos(\S+)/
      sdk_versions["watchOS"] = $1
    end
  end
  return sdk_versions
end

# libsodium release version
PKG_VER                 = "1.0.11"

# Minimum platform versions
IOS_VERSION_MIN         = 9.0
MACOS_VERSION_MIN       = 10.11
TVOS_VERSION_MIN        = 9.0
WATCHOS_VERSION_MIN     = 2.0

LIBNAME                 = "libsodium.a"
VALID_ARHS_PER_PLATFORM = {
  "iOS"     => ["armv7", "armv7s", "arm64", "i386", "x86_64"],
  "macOS"   => ["x86_64"],
  "tvOS"    => ["arm64", "x86_64"],
  "watchOS" => ["armv7k", "i386"],
}
DEVELOPER               = `xcode-select -print-path`.chomp
LIPO                    = `xcrun -sdk iphoneos -find lipo`.chomp
# Script's directory
SCRIPTDIR               = File.absolute_path(File.dirname(__FILE__))
# libsodium root directory
LIBDIR                  = File.join(SCRIPTDIR, "build/libsodium")
# Destination directory for build and install
DSTDIR                  = SCRIPTDIR
BUILDDIR                = "#{DSTDIR}/build"
DISTDIR                 = "#{DSTDIR}/dist"
DISTLIBDIR              = "#{DISTDIR}/lib"

sdk_versions            = find_sdks()
IOS_SDK_VERSION         = sdk_versions["iOS"]
MACOS_SDK_VERSION       = sdk_versions["macOS"]
TVOS_SDK_VERSION        = sdk_versions["tvOS"]
WATCHOS_SDK_VERSION     = sdk_versions["watchOS"]

puts "iOS     SDK version = #{IOS_SDK_VERSION}"
puts "macOS   SDK version = #{MACOS_SDK_VERSION}"
puts "watchOS SDK version = #{WATCHOS_SDK_VERSION}"
puts "tvOS    SDK version = #{TVOS_SDK_VERSION}"

OTHER_CFLAGS            = "-Os -Qunused-arguments"

# Cleanup
if File.directory? BUILDDIR
    FileUtils.rm_rf BUILDDIR
end
if File.directory? DISTDIR
    FileUtils.rm_rf DISTDIR
end
FileUtils.mkdir_p BUILDDIR
FileUtils.mkdir_p DISTDIR

# Download/extract libsodium into build folder
download_and_extract_libsodium()

PLATFORMS = sdk_versions.keys
libs_per_platform = {}

# Compile libsodium for each Apple device platform
for platform in PLATFORMS
  # Compile libsodium for each valid Apple device architecture
  archs = VALID_ARHS_PER_PLATFORM[platform]
  for arch in archs
    puts "Building #{platform}/#{arch}..."
    build_arch_dir=File.absolute_path("#{BUILDDIR}/#{platform}-#{arch}")
    FileUtils.mkdir_p(build_arch_dir)

    build_type = "#{platform}-#{arch}"
    case build_type
    when "iOS-armv7"
      # iOS 32-bit ARM (till iPhone 4s)
      platform_name   = "iPhoneOS"
      host            = "#{arch}-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{IOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} -mios-version-min=#{IOS_VERSION_MIN} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-mthumb -arch #{arch} -isysroot #{isdk_root}"
    when "iOS-armv7s"
      # iOS 32-bit ARM (iPhone 5 till iPhone 5c)
      platform_name   = "iPhoneOS"
      host            = "#{arch}-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{IOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} -mios-version-min=#{IOS_VERSION_MIN} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-mthumb -arch #{arch} -isysroot #{isdk_root}"
    when "watchOS-armv7k"
      # watchOS 32-bit ARM
      platform_name   = "WatchOS"
      host            = "#{arch}-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{WATCHOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} -mwatchos-version-min=#{WATCHOS_VERSION_MIN} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-mthumb -arch #{arch} -isysroot #{isdk_root}"
    when "iOS-arm64"
      # iOS 64-bit ARM (iPhone 5s and later)
      platform_name   = "iPhoneOS"
      host            = "arm-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{IOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root}  -mios-version-min=#{IOS_VERSION_MIN} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-mthumb -arch #{arch} -isysroot #{isdk_root}"
    when "tvOS-arm64"
      # tvOS 64-bit ARM (Apple TV 4)
      platform_name   = "AppleTVOS"
      host            = "arm-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{TVOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} -mtvos-version-min=#{TVOS_VERSION_MIN} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-mthumb -arch #{arch} -isysroot #{isdk_root}"
        #   tvsos-version-min?
    when "iOS-i386"
      # iOS 32-bit simulator (iOS 6.1 and below)
      platform_name   = "iPhoneSimulator"
      host            = "#{arch}-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{IOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} -mios-version-min=#{IOS_VERSION_MIN} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-m32 -arch #{arch}"
    when "macOS-i386"
      # macOS 32-bit
      platform_name   = "MacOSX"
      host            = "#{arch}-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{MACOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} -mmacosx-version-min=#{MACOS_VERSION_MIN} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-m32 -arch #{arch}"
    when "watchOS-i386"
      # watchOS 32-bit simulator
      platform_name   = "WatchSimulator"
      host            = "#{arch}-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{WATCHOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} -mwatchos-version-min=#{WATCHOS_VERSION_MIN} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-m32 -arch #{arch}"
    when "iOS-x86_64"
      # iOS 64-bit simulator (iOS 7+)
      platform_name   = "iPhoneSimulator"
      host            = "#{arch}-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{IOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} -mios-version-min=#{IOS_VERSION_MIN} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-arch #{arch}"
    when "macOS-x86_64"
      # macOS 64-bit
      platform_name   = "MacOSX"
      host            = "#{arch}-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{MACOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} -mmacosx-version-min=#{MACOS_VERSION_MIN} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-arch #{arch}"
    when "tvOS-x86_64"
      # tvOS 64-bit simulator
      platform_name   = "AppleTVSimulator"
      host            = "#{arch}-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{TVOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} -mtvos-version-min=#{TVOS_VERSION_MIN} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-arch #{arch}"
    else
      warn "Unsupported platform/architecture #{build_type}"
      next
      #exit 1
    end

    # Modify path to include Xcode toolchain path
    ENV["PATH"] = "#{DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin:" +
      "#{DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/sbin:#{ENV["PATH"]}"

    puts "Configuring for #{arch}..."
    FileUtils.cd(LIBDIR)
    configure_cmd = [
      "./configure",
      "--prefix=#{build_arch_dir}",
      "--disable-shared",
      "--enable-static",
      "--host=#{host}",
    ]
    exit 1 unless system(configure_cmd.join(" "))

    puts "Building #{LIBNAME} for #{arch}..."
    exit 1 unless system("make clean")
    exit 1 unless system("make -j8 V=0")
    exit 1 unless system("make install")

    # Add to the architecture-dependent library list for the current platform
    libs = libs_per_platform[platform]
    if libs == nil
      libs_per_platform[platform] = libs = []
    end
    libs.push "#{build_arch_dir}/lib/#{LIBNAME}"
  end
end

# Build a single universal (fat) library file for each platform
FileUtils.mkdir_p DISTLIBDIR
for platform in PLATFORMS
  # Find libraries for platform
  lib_name = "libsodium-#{platform}.a"
  libs     = libs_per_platform[platform]

  # Make sure library list is not empty
  if libs == nil || libs.length == 0
    warn "Nothing to do for #{lib_name}"
    next
  end

  # Build universal library file (aka fat binary)
  lipo_cmd = "#{LIPO} -create #{libs.join(" ")} -output #{DISTLIBDIR}/#{lib_name}"
  puts "Combining #{libs.length} libraries into #{lib_name}..."
  exit 1 unless system(lipo_cmd)

end

# Copy headers once (they are the same since we're using make install)
for platform in PLATFORMS
  for arch in VALID_ARHS_PER_PLATFORM["iOS"]
      include_dir = "#{BUILDDIR}/#{platform}-#{arch}/include"
      if File.directory? include_dir
        FileUtils.cp_r(include_dir, DISTDIR)
        break
      end
  end
end

# Cleanup
FileUtils.rm_rf BUILDDIR
