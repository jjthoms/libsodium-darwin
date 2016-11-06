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
PKG_VER="1.0.11"

# Download and extract the latest stable release indicated by PKG_VER variable
puts "Downloading latest stable release of 'libsodium'"
libsodium_dir = "libsodium"
FileUtils.rm_rf libsodium_dir
libsodium_dist="libsodium-#{PKG_VER}.tar.gz"
url = "https://github.com/jedisct1/libsodium/releases/download/#{PKG_VER}/#{libsodium_dist}"
exit 1 unless system("curl -O -L #{url}")
exit 1 unless system("tar xzf #{libsodium_dist}")
FileUtils.mv "libsodium-#{PKG_VER}", libsodium_dir
FileUtils.rm_rf libsodium_dist

exit 1
=begin


LIBNAME="libsodium.a"
ARCHS=${ARCHS:-"armv7 armv7s arm64 i386 x86_64"}
DEVELOPER=$(xcode-select -print-path)
LIPO=$(xcrun -sdk iphoneos -find lipo)
# Script's directory
SCRIPTDIR=$( (cd -P $(dirname $0) && pwd) )
# libsodium root directory
LIBDIR=$( (cd "${SCRIPTDIR}/libsodium"  && pwd) )
# Destination directory for build and install
DSTDIR=${SCRIPTDIR}
BUILDDIR="${DSTDIR}/libsodium_build"
DISTDIR="${DSTDIR}/libsodium_dist"
DISTLIBDIR="${DISTDIR}/lib"
# http://libwebp.webm.googlecode.com/git/iosbuild.sh
# Extract the latest SDK version from the final field of the form: iphoneosX.Y
IOS_SDK_VERSION=$(xcodebuild -showsdks \
    | grep iphoneos | sort | tail -n 1 | awk '{print substr($NF, 9)}'
    )
MACOS_SDK_VERSION=$(xcodebuild -showsdks \
    | grep macos | sort | tail -n 1 | awk '{print substr($NF, 7)}'
    )
WATCHOS_SDK_VERSION=$(xcodebuild -showsdks \
    | grep watchos | sort | tail -n 1 | awk '{print substr($NF, 8)}'
    )
TVOS_SDK_VERSION=$(xcodebuild -showsdks \
    | grep appletvos | sort | tail -n 1 | awk '{print substr($NF, 10)}'
    )
echo "iOS     SDK version = ${IOS_SDK_VERSION}"
echo "macOS   SDK version = ${MACOS_SDK_VERSION}"
echo "watchOS SDK version = ${WATCHOS_SDK_VERSION}"
echo "tvOS    SDK version = ${TVOS_SDK_VERSION}"

OTHER_CFLAGS="-Os -Qunused-arguments"

# Cleanup
if [ -d $BUILDDIR ]
then
    rm -rf $BUILDDIR
fi
if [ -d $DISTDIR ]
then
    rm -rf $DISTDIR
fi
mkdir -p $BUILDDIR $DISTDIR

# Generate autoconf files
cd ${LIBDIR}; ./autogen.sh

# Iterate over archs and compile static libs
for ARCH in $ARCHS
do
    BUILDARCHDIR="$BUILDDIR/$ARCH"
    mkdir -p ${BUILDARCHDIR}

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