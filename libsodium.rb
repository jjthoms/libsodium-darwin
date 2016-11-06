#!/usr/bin/env ruby

#
# A Ruby script to download and build libsodium for iOS, macOS, tvOS and watchOS
# Adapted from https://github.com/drewcrawford/libsodium-ios/blob/master/libsodium.sh
#

require 'FileUtils'
require 'open-uri'

#
# libsodium release version
# Please visit https://github.com/jedisct1/libsodium/releases
#

# Download and extract the latest stable release indicated by PKG_VER variable
def download_and_extract_libsodium()
  puts "Downloading latest stable release of 'libsodium'"
  libsodium_dir = "libsodium"
  FileUtils.rm_rf libsodium_dir
  pkg_name      = "libsodium-#{PKG_VER}"
  pkg           = "#{pkg_name}.tar.gz"
  url           = "https://github.com/jedisct1/libsodium/releases/download/#{PKG_VER}/#{pkg}"
  exit 1 unless system("curl -O -L #{url}")
  exit 1 unless system("tar xzf #{pkg}")
  FileUtils.mv pkg_name, libsodium_dir
  FileUtils.rm_rf pkg
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

PKG_VER                 = "1.0.11"
download_and_extract_libsodium()

LIBNAME                 = "libsodium.a"
VALID_ARHS_PER_PLATFORM = {
  "iOS"     => ["armv7", "armv7s", "arm64", "i386", "x86_64"],
  "macOS"   => ["x86_64"],
  "tvOS"    => ["arm64","i386", "x86_64"],
  "watchOS" => ["armv7k","i386", "x86_64"],
}
DEVELOPER               = `xcode-select -print-path`.chomp
LIPO                    = `xcrun -sdk iphoneos -find lipo`.chomp
# Script's directory
SCRIPTDIR               = File.absolute_path(File.dirname(__FILE__))
# libsodium root directory
LIBDIR                  = File.join(SCRIPTDIR, "libsodium")
# Destination directory for build and install
DSTDIR                  = SCRIPTDIR
BUILDDIR                = "#{DSTDIR}/libsodium_build"
DISTDIR                 = "#{DSTDIR}/libsodium_dist"
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

PLATFORMS = sdk_versions.keys
lib_list = []
# Compile libsodium for each Apple device platform
for platform in PLATFORMS
  # Compile libsodium for each valid Apple device architecture
  archs = VALID_ARHS_PER_PLATFORM[platform]
  for arch in archs
    puts "Building #{platform}/#{arch}..."
    build_arch_dir=File.absolute_path("#{BUILDDIR}/#{platform}-#{arch}")
    FileUtils.mkdir_p(build_arch_dir)

    case arch
    when "armv7"
      platform_name   = "iPhoneOS"
      host            = "#{arch}-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{IOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-mthumb -arch #{arch} -isysroot #{isdk_root}"
    when "armv7s"
      platform_name   = "iPhoneOS"
      host            = "#{arch}-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{IOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-mthumb -arch #{arch} -isysroot #{isdk_root}"
    when "arm64"
      if platform == "iOS"
        # iOS
        platform_name   = "iPhoneOS"
        host            = "arm-apple-darwin"
        base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
        ENV["BASEDIR"]  = base_dir
        isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{IOS_SDK_VERSION}.sdk"
        ENV["ISDKROOT"] = isdk_root
        ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} #{OTHER_CFLAGS}"
        ENV["LDFLAGS"]  = "-mthumb -arch #{arch} -isysroot #{isdk_root}"
      else
        # tvOS
        platform_name   = "AppleTVOS"
        host            = "arm-apple-darwin"
        base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
        ENV["BASEDIR"]  = base_dir
        isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{TVOS_SDK_VERSION}.sdk"
        ENV["ISDKROOT"] = isdk_root
        ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} #{OTHER_CFLAGS}"
        ENV["LDFLAGS"]  = "-mthumb -arch #{arch} -isysroot #{isdk_root}"
        #   tvsos-version-min?
      end
    when "i386"
      platform_name   = "iPhoneSimulator"
      host            = "#{arch}-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{IOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} -mios-version-min=#{IOS_SDK_VERSION} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-m32 -arch #{arch}"
    when "x86_64"
      platform_name   = "iPhoneSimulator"
      host            = "#{arch}-apple-darwin"
      base_dir        = "#{DEVELOPER}/Platforms/#{platform_name}.platform/Developer"
      ENV["BASEDIR"]  = base_dir
      isdk_root       = "#{base_dir}/SDKs/#{platform_name}#{IOS_SDK_VERSION}.sdk"
      ENV["ISDKROOT"] = isdk_root
      ENV["CFLAGS"]   = "-arch #{arch} -isysroot #{isdk_root} -mios-version-min=#{IOS_SDK_VERSION} #{OTHER_CFLAGS}"
      ENV["LDFLAGS"]  = "-arch #{arch}"
      # tvOS
      #   appletvsimulator10.0
      #   PLATFORM=AppleTVOS
      #   appletvos10.0
      #   PLATFORM=AppleTVSimulator
      #   tvsos-version-min?
      # watchOS
      #   watchos3.0
      #   watchsimulator3.0
      #   PLATFORM=WatchOS
      #   PLATFORM=WatchSimulator
      #   watchos-version-min?
    else
      warn "Unsupported architecture #{arch}"
      break
      #exit 1
    end

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

    lib_list.push "#{build_arch_dir}/lib/#{LIBNAME}"
  end
end

# Copy headers and generate a single fat library file
FileUtils.mkdir_p DISTLIBDIR
exit 1 unless system("#{LIPO} -create #{lib_list.join(" ")} -output #{DISTLIBDIR}/#{LIBNAME}")
for arch in VALID_ARHS_PER_PLATFORM["iOS"]
    FileUtils.cp_r("#{BUILDDIR}/#{arch}/include", DISTDIR)
    break
end

# Cleanup
FileUtils.rm_rf BUILDDIR
