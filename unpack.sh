#!/bin/bash

printf "\e[1;32m \u2730 Recovery Boot IMG Unpacker\e[0m\n\n"

echo "::group::Download File"
git clone https://android.googlesource.com/platform/system/tools/mkbootimg && cd mkbootimg
wget $LINK &>/dev/null
echo "::endgroup::"

echo "::group::Unpacking"
export TAR=$(find * -name *.tgz)
export ZIP=$(find * -name *.zip)

if [[ -f "$TAR" ]]; then
    printf "Unpacking TAR file\n"
    tar -vxf $TAR
elif [[ -f "$ZIP" ]]; then
    printf "Unpacking ZIP file\n"
    unzip $ZIP
fi

export RECOVERYIMAGE=$(find * -name recovery.img)
export BOOTIMAGE=$(find * -name boot.img)

if [[ -f "$BOOTIMAGE" ]]; then
printf "Found & Unpacking Boot Image\n"
python unpack_bootimg.py --boot_img $BOOTIMAGE --out tmp | tee img_info
elif [[ -f "$RECOVERYIMAGE" ]]; then
printf "Found & Unpacking Recovery Image\n"
python unpack_bootimg.py --boot_img $RECOVERYIMAGE --out tmp | tee img_info
elif [[ ! -f "$RECOVERYIMAGE" ]] && [[ ! -f "$BOOTIMAGE" ]]; then
export IMAGE=$(find * -name *.img)
printf "Found & Unpacking Recovery/Boot Image\n"
python unpack_bootimg.py --boot_img $IMAGE --out tmp | tee img_info
fi
mv img_info tmp/img_info

unpack_complete()
{
    [ ! -z $format ] && echo ramdisk format: $format | tee -a ../img_info
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
