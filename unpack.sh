#!/bin/bash

printf "\e[1;32m \u2730 Recovery Boot IMG Unpacker\e[0m\n\n"

echo "::group::Download File"
git clone https://android.googlesource.com/platform/system/tools/mkbootimg && cd mkbootimg
wget $LINK
echo "::endgroup::"

echo "::group::Unpacking"
export TAR=$(find . -name *.tgz)
export ZIP=$(find . -name *.zip)

if [[ ! -z "$TAR" ]]; then
    printf "Unpacking TAR file\n"
    export RECOVERYTAR=$(tar -tzf *.tgz | grep recovery.img)
    tar -vxf *.tgz $RECOVERYTAR || exit
fi

if [[ ! -z "$ZIP" ]]; then
    printf "Unpacking ZIP file\n"
    export RECOVERYZIP=$(zip -sf *zip | grep recovery.img)
    unzip *.zip $RECOVERYZIP || exit
fi

export RECOVERYIMAGE=$(find . -name *.img)
python unpack_bootimg.py --boot_img $RECOVERYIMAGE --out tmp &> img_info
mv img_info tmp/img_info

unpack_complete()
{
    [ ! -z $format ] && echo ramdisk format: $format >> ../img_info
}

cd tmp && mkdir unpacked-ramdisk && cd unpacked-ramdisk

if gzip -t ../ramdisk 2>/dev/null; then
    printf "ramdisk is gzip format."
    format=gzip
    gzip -d -c ../ramdisk | cpio -i -d -m --no-absolute-filenames 2>/dev/null
    unpack_complete
fi
if lzma -t ../ramdisk 2>/dev/null; then
    printf "ramdisk is lzma format."
    format=lzma
    lzma -d -c ../ramdisk | cpio -i -d -m --no-absolute-filenames 2>/dev/null
    unpack_complete
fi
if xz -t ../ramdisk 2>/dev/null; then
    printf "ramdisk is xz format."
    format=xz
    xz -d -c ../ramdisk | cpio -i -d -m --no-absolute-filenames 2>/dev/null
    unpack_complete
fi
if lzop -t ../ramdisk 2>/dev/null; then
    printf "ramdisk is lzo format."
    format=lzop
    lzop -d -c ../ramdisk | cpio -i -d -m --no-absolute-filenames 2>/dev/null
    unpack_complete
fi
if lz4 -d ../ramdisk 2>/dev/null | cpio -i -d -m --no-absolute-filenames 2>/dev/null; then
    printf "ramdisk is lz4 format."
    format=lz4
fi
echo "::endgroup::"

echo "::group::Push To Github"
cd ..
git init
git remote add origin https://$GITHUB_ACTOR:$GH_TOKEN@github.com/${GITHUB_REPOSITORY}
git config --global user.email "raza231198@gmail.com"
git config --global user.name "MD Raza"
git add .
git commit -m "unpacked $VERSION" &>/dev/null
git checkout -b $VERSION
git push origin +$VERSION
echo "::endgroup::"
