#!/bin/sh

INSTALL_PATH=/opt/yami
LIBDRM_CONFIG="--disable-radeon --disable-amdgpu --disable-nouveau --disable-vmwgfx --disable-libkms"
LIBVA_CONFIG="--disable-x11 --disable-wayland"
LIBVAUTILS_CONFIG="--disable-x11 --disable-wayland"
LIBVA_INTER_DRIVER_CONFIG="--disable-x11 --disable-wayland"
LIBYAMI_CONFIG="--disable-jpegdec --disable-vp8dec --disable-h265dec --enable-capi --disable-x11 --enable-mpeg2dec"
SHOW_HELP=0
ENABLE_X11=0
GOT_PARAM=0
ENABLE_IHD=0

LIBDRM_VER="2.4.100"
LIBDRM_SRC_NAME="libdrm-$LIBDRM_VER"
LIBDRM_SRC_FILE="$LIBDRM_SRC_NAME.tar.gz"
LIBDRM_DIR_NAME="$LIBDRM_SRC_NAME"

LIBVA_VER="2.20.0"
LIBVA_SRC_NAME="libva-$LIBVA_VER"
LIBVA_SRC_FILE="$LIBVA_SRC_NAME.tar.bz2"
LIBVA_DIR_NAME="$LIBVA_SRC_NAME"

LIBVAUTILS_VER="2.20.0"
LIBVAUTILS_SRC_NAME="libva-utils-$LIBVAUTILS_VER"
LIBVAUTILS_SRC_FILE="$LIBVAUTILS_SRC_NAME.tar.bz2"
LIBVAUTILS_DIR_NAME="$LIBVAUTILS_SRC_NAME"

LIBVA_INTER_DRIVER_VER="2.4.1"
LIBVA_INTER_DRIVER_SRC_NAME="intel-vaapi-driver-$LIBVA_INTER_DRIVER_VER"
LIBVA_INTER_DRIVER_SRC_FILE="$LIBVA_INTER_DRIVER_SRC_NAME.tar.bz2"
LIBVA_INTER_DRIVER_DIR_NAME="$LIBVA_INTER_DRIVER_SRC_NAME"

INTEL_GMM_VER="22.3.7"
INTEL_GMM_SRC_NAME="intel-gmmlib-$INTEL_GMM_VER"
INTEL_GMM_SRC_FILE="$INTEL_GMM_SRC_NAME.tar.gz"
INTEL_GMM_DIR_NAME="gmmlib-intel-gmmlib-$INTEL_GMM_VER"

INTEL_MEDIA_VER="23.2.4"
INTEL_MEDIA_SRC_NAME="intel-media-$INTEL_MEDIA_VER"
INTEL_MEDIA_SRC_FILE="$INTEL_MEDIA_SRC_NAME.tar.gz"
INTEL_MEDIA_DIR_NAME="media-driver-intel-media-$INTEL_MEDIA_VER"

LIBYAMI_INF_CONFIG=

for i in "$@"
do
case $i in
    --prefix=*)
    INSTALL_PATH="${i#*=}"
    GOT_PARAM=1
    shift # past argument=value
    ;;
    --enable-x11)
    ENABLE_X11=1
    GOT_PARAM=1
    shift # past argument=value
    ;;
    --disable-x11)
    ENABLE_X11=0
    shift # past argument=value
    ;;
    --enable-ihd)
    ENABLE_IHD=1
    shift # past argument=value
    ;;
    --enable-iHD)
    ENABLE_IHD=1
    shift # past argument=value
    ;;
    *)
          # unknown option
    SHOW_HELP=1
    ;;
esac
done

if test $GOT_PARAM -eq 0
then
    SHOW_HELP=1
fi

if test $SHOW_HELP -ne 0
then
    echo "./buildyami.sh [--prefix=/opt/yami] [--enable-x11 | --disable-x11 | --enable-iHD]"
    exit 0
fi

if test $ENABLE_X11 -ne 0
then
    LIBVA_CONFIG="--enable-x11 --disable-wayland"
    LIBVAUTILS_CONFIG="--enable-x11 --disable-wayland"
    LIBVA_INTER_DRIVER_CONFIG="--enable-x11 --disable-wayland"
    LIBYAMI_CONFIG="--disable-jpegdec --disable-vp8dec --disable-h265dec --enable-capi --enable-x11 --enable-mpeg2dec"
    LIBYAMI_INF_CONFIG="--enable-x11"
fi

echo "INSTALL_PATH              = $INSTALL_PATH"
echo "LIBDRM_CONFIG             = $LIBDRM_CONFIG"
echo "LIBVA_CONFIG              = $LIBVA_CONFIG"
echo "LIBVAUTILS_CONFIG         = $LIBVAUTILS_CONFIG"
echo "LIBVA_INTER_DRIVER_CONFIG = $LIBVA_INTER_DRIVER_CONFIG"
echo "LIBYAMI_CONFIG            = $LIBYAMI_CONFIG"

export PKG_CONFIG_PATH=$INSTALL_PATH/lib/pkgconfig
export NOCONFIGURE=1

rm -rf $INSTALL_PATH/*

check_download_file()
{
  if test -f $1
  then
    HASH=$(md5sum $1 | head -n1 | sed -e 's/\s.*$//')
    if test "$HASH" = "$2"
    then
      echo "file $1 ok, not downloaded"
      return 0
    else
      rm -f $1
    fi
  fi
  wget $3/$1
  if test $? -ne 0
  then
    echo "error downloading $1"
    exit 1
  fi
  return 0
}

#wget https://dri.freedesktop.org/libdrm/$LIBDRM_SRC_NAME.tar.gz

#wget https://www.freedesktop.org/software/vaapi/releases/libva/$LIBVA_SRC_NAME.tar.bz2
#wget https://github.com/01org/libva/releases/download/2.3.0/$LIBVA_SRC_NAME.tar.bz2
#wget http://server1.xrdp.org/yami/$LIBVA_SRC_NAME.tar.bz2

#wget https://www.freedesktop.org/software/vaapi/releases/libva/$LIBVAUTILS_SRC_NAME.tar.bz2
#wget https://github.com/intel/libva-utils/releases/download/2.2.0/$LIBVAUTILS_SRC_NAME.tar.bz2
#wget http://server1.xrdp.org/yami/$LIBVAUTILS_SRC_NAME.tar.bz2

#wget https://www.freedesktop.org/software/vaapi/releases/libva-intel-driver/$LIBVA_INTER_DRIVER_SRC_NAME.tar.bz2
#wget https://github.com/intel/intel-vaapi-driver/releases/download/2.3.0/$LIBVA_INTER_DRIVER_SRC_NAME.tar.bz2
#wget http://server1.xrdp.org/yami/$LIBVA_INTER_DRIVER_SRC_NAME.tar.bz2

check_download_file "$LIBDRM_SRC_FILE" \
                    "c47b1718734cc661734ed63f94bc27c1" \
                    "http://server1.xrdp.org/yami"
check_download_file "$LIBVA_SRC_FILE" \
                    "cde8e62a027f6cad023895c6f38ba58e" \
                    "https://github.com/intel/libva/releases/download/$LIBVA_VER"
check_download_file "$LIBVAUTILS_SRC_FILE" \
                    "ec343e7b2011e7fd5bf17208f8d7ce8a" \
                    "https://github.com/intel/libva-utils/releases/download/$LIBVAUTILS_VER"
check_download_file "$LIBVA_INTER_DRIVER_SRC_FILE" \
                    "073fce0f409559109ad2dd0a6531055d" \
                    "https://github.com/intel/intel-vaapi-driver/releases/download/$LIBVA_INTER_DRIVER_VER"

if test $ENABLE_IHD -ne 0
then
  check_download_file "$INTEL_GMM_SRC_FILE" \
                      "522c2db1615a08279b78889aa14af473" \
                      "https://github.com/intel/gmmlib/archive/refs/tags"
  check_download_file "$INTEL_MEDIA_SRC_FILE" \
                      "68ded8a286c01c1c70fd73925279d12b" \
                      "https://github.com/intel/media-driver/archive/refs/tags"
fi

rm -fr $LIBDRM_DIR_NAME
tar -zxf $LIBDRM_SRC_NAME.tar.gz
cd $LIBDRM_DIR_NAME
./configure --prefix=$INSTALL_PATH $LIBDRM_CONFIG
if test $? -ne 0
then
  echo "error configure $LIBDRM_SRC_NAME"
  exit 1
fi
make
if test $? -ne 0
then
  echo "error make $LIBDRM_SRC_NAME"
  exit 1
fi
make install-strip
if test $? -ne 0
then
  echo "error make install $LIBDRM_SRC_NAME"
  exit 1
fi
cd ..

rm -fr $LIBVA_DIR_NAME
bunzip2 -k $LIBVA_SRC_FILE
tar -xf $LIBVA_SRC_NAME.tar
rm $LIBVA_SRC_NAME.tar
cd $LIBVA_DIR_NAME
./configure --prefix=$INSTALL_PATH $LIBVA_CONFIG
if test $? -ne 0
then
  echo "error configure $LIBVA_SRC_NAME"
  exit 1
fi
# this will get rid of libva info logging
echo "" >> config.h
echo "#define va_log_info(buffer)" >> config.h
echo "" >> config.h
make
if test $? -ne 0
then
  echo "error make $LIBVA_SRC_NAME"
  exit 1
fi
make install-strip
if test $? -ne 0
then
  echo "error make install $LIBVA_SRC_NAME"
  exit 1
fi
cd ..

rm -fr $LIBVAUTILS_DIR_NAME
bunzip2 -k $LIBVAUTILS_SRC_FILE
tar -xf $LIBVAUTILS_SRC_NAME.tar
rm $LIBVAUTILS_SRC_NAME.tar
cd $LIBVAUTILS_DIR_NAME
./configure --prefix=$INSTALL_PATH $LIBVAUTILS_CONFIG
if test $? -ne 0
then
  echo "error configure $LIBVAUTILS_SRC_NAME"
  exit 1
fi
make
if test $? -ne 0
then
  echo "error make $LIBVAUTILS_SRC_NAME"
  exit 1
fi
make install-strip
if test $? -ne 0
then
  echo "error make install $LIBVAUTILS_SRC_NAME"
  exit 1
fi
cd ..

rm -rf $LIBVA_INTER_DRIVER_DIR_NAME
bunzip2 -k $LIBVA_INTER_DRIVER_SRC_FILE
tar -xf $LIBVA_INTER_DRIVER_SRC_NAME.tar
rm $LIBVA_INTER_DRIVER_SRC_NAME.tar
cd $LIBVA_INTER_DRIVER_DIR_NAME
echo "patching $LIBVA_INTER_DRIVER_SRC_NAME"
patch -p1 < ../0002-RGB-YUV-fix.patch
if test $? -ne 0
then
  echo "patching $LIBVA_INTER_DRIVER_SRC_NAME failed"
  exit 1
fi
./configure --prefix=$INSTALL_PATH $LIBVA_INTER_DRIVER_CONFIG
if test $? -ne 0
then
  echo "error configure $LIBVA_INTER_DRIVER_SRC_NAME"
  exit 1
fi
make
if test $? -ne 0
then
  echo "error make $LIBVA_INTER_DRIVER_SRC_NAME"
  exit 1
fi
make install-strip
if test $? -ne 0
then
  echo "error make install $LIBVA_INTER_DRIVER_SRC_NAME"
  exit 1
fi
cd ..

if test $ENABLE_IHD -ne 0
then
  rm -rf $INTEL_GMM_DIR_NAME
  tar -xf $INTEL_GMM_SRC_FILE
  mkdir $INTEL_GMM_DIR_NAME/build
  cd $INTEL_GMM_DIR_NAME/build
  PKG_CONFIG_PATH=$INSTALL_PATH/lib/pkgconfig cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH
  if test $? -ne 0
  then
    echo "error configure $INTEL_GMM_DIR_NAME"
    exit 1
  fi
  make
  if test $? -ne 0
  then
    echo "error make $INTEL_GMM_DIR_NAME"
    exit 1
  fi
  make install
  if test $? -ne 0
  then
    echo "error make install $INTEL_GMM_DIR_NAME"
    exit 1
  fi
  strip $INSTALL_PATH/lib/libigdgmm.so
  cd ..
  cd ..

  rm -rf $INTEL_MEDIA_DIR_NAME
  tar -xf $INTEL_MEDIA_SRC_FILE
  mkdir $INTEL_MEDIA_DIR_NAME/build
  cd $INTEL_MEDIA_DIR_NAME/build
  PKG_CONFIG_PATH=$INSTALL_PATH/lib/pkgconfig cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH
  if test $? -ne 0
  then
    echo "error configure $INTEL_MEDIA_DIR_NAME"
    exit 1
  fi
  make
  if test $? -ne 0
  then
    echo "error make $INTEL_MEDIA_DIR_NAME"
    exit 1
  fi
  make install
  if test $? -ne 0
  then
    echo "error make install $INTEL_MEDIA_DIR_NAME"
    exit 1
  fi
  strip $INSTALL_PATH/lib/libigfxcmrt.so
  strip $INSTALL_PATH/lib/dri/iHD_drv_video.so
  cd ..
  cd ..
fi

rm -rf libyami
git clone https://github.com/intel/libyami.git
#git clone https://github.com/01org/libyami.git
#git clone https://github.com/xuguangxin/libyami.git
#git clone https://github.com/jsorg71/libyami.git
#git clone https://github.com/lizhong1008/libyami.git
cd libyami
#git checkout infinte_gop
#git checkout apache
#git checkout fa3865a3406f9f21b729d5b6d46536a7e70eb391
#git checkout 1.1.0
#git checkout 1.2.0
#git checkout 1.3.0
git checkout 1.3.2
#git checkout libyami-0.3.1
#git checkout fix_low_latency
./autogen.sh
CFLAGS="-O2 -Wall" CXXFLAGS="-O2 -Wall" ./configure --prefix=$INSTALL_PATH $LIBYAMI_CONFIG
if test $? -ne 0
then
  echo "error configure libyami"
  exit 1
fi
make clean
make
if test $? -ne 0
then
  echo "error make libyami"
  exit 1
fi
make install-strip
if test $? -ne 0
then
  echo "error make install libyami"
  exit 1
fi
cd ..

cd yami_inf
./bootstrap
if test $? -ne 0
then
  echo "error bootstrap yami_inf"
  exit 1
fi
./configure --prefix=$INSTALL_PATH $LIBYAMI_INF_CONFIG
if test $? -ne 0
then
  echo "error configure yami_inf"
  exit 1
fi
make clean
make
if test $? -ne 0
then
  echo "error make yami_inf"
  exit 1
fi
make install-strip
if test $? -ne 0
then
  echo "error make install yami_inf"
  exit 1
fi
cd ..

