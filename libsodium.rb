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
  sdks=`xcodebuild -showsdks`
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
DEVELOPER               = `xcode-select -print-path`
LIPO                    = `xcrun -sdk iphoneos -find lipo`
# Script's directory
SCRIPTDIR               = File.dirname(__FILE__)
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

# Generate autoconf files
FileUtils.cd(LIBDIR)
#exit 1 unless system('./autogen.sh')

PLATFORMS = sdk_versions.keys
# Compile libsodium for each Apple device platform
for platform in PLATFORMS
  # Compile libsodium for each valid Apple device architecture
  archs = VALID_ARHS_PER_PLATFORM[platform]
  for arch in archs
    puts "Building #{platform}/#{arch}..."
    build_arch_dir="#{BUILDDIR}/#{arch}"
    FileUtils.mkdir_p(build_arch_dir)
  end
end

exit 1
=begin
for ARCH in $ARCHS
do
    case ${ARCH} in
        armv7)
	    PLATFORM="iPhoneOS"
	    HOST="${ARCH}-apple-darwin"
	    export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	    export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${IOS_SDK_VERSION}.sdk"
	    export CFLAGS="-arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_CFLAGS}"
	    export LDFLAGS="-mthumb -arch ${ARCH} -isysroot ${ISDKROOT}"
            ;;
        armv7s)
	    PLATFORM="iPhoneOS"
	    HOST="${ARCH}-apple-darwin"
	    export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	    export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${IOS_SDK_VERSION}.sdk"
	    export CFLAGS="-arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_CFLAGS}"
	    export LDFLAGS="-mthumb -arch ${ARCH} -isysroot ${ISDKROOT}"
            ;;
        arm64)
	    PLATFORM="iPhoneOS"
	    HOST="arm-apple-darwin"
	    export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	    export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${IOS_SDK_VERSION}.sdk"
	    export CFLAGS="-arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_CFLAGS}"
	    export LDFLAGS="-mthumb -arch ${ARCH} -isysroot ${ISDKROOT}"
            ;;
        i386)
	    PLATFORM="iPhoneSimulator"
	    HOST="${ARCH}-apple-darwin"
	    export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	    export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${IOS_SDK_VERSION}.sdk"
	    export CFLAGS="-arch ${ARCH} -isysroot ${ISDKROOT} -miphoneos-version-min=${IOS_SDK_VERSION} ${OTHER_CFLAGS}"
	    export LDFLAGS="-m32 -arch ${ARCH}"
            ;;
        x86_64)
	    PLATFORM="iPhoneSimulator"
	    HOST="${ARCH}-apple-darwin"
	    export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	    export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${IOS_SDK_VERSION}.sdk"
	    export CFLAGS="-arch ${ARCH} -isysroot ${ISDKROOT} -miphoneos-version-min=${IOS_SDK_VERSION} ${OTHER_CFLAGS}"
	    export LDFLAGS="-arch ${ARCH}"
            ;;
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
        *)
            echo "Unsupported architecture ${ARCH}"
            exit 1
            ;;
    esac

    export PATH="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin:${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/sbin:$PATH"

    echo "Configuring for ${ARCH}..."
    ${LIBDIR}/configure \
	--prefix=${BUILDARCHDIR} \
	--disable-shared \
	--enable-static \
	--host=${HOST}

    echo "Building ${LIBNAME} for ${ARCH}..."
    cd ${LIBDIR}
    make clean
    make -j8 V=0
    make install

    LIBLIST+="${BUILDARCHDIR}/lib/${LIBNAME} "
done

# Copy headers and generate a single fat library file
mkdir -p ${DISTLIBDIR}
${LIPO} -create ${LIBLIST} -output ${DISTLIBDIR}/${LIBNAME}
for ARCH in $ARCHS
do
    cp -R $BUILDDIR/$ARCH/include ${DISTDIR}
    break
done

# Cleanup
rm -rf ${BUILDDIR}
=end