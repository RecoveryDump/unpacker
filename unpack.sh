#!/bin/bash

printf "\e[1;32m \u2730 Recovery Boot IMG Unpacker\e[0m\n\n"

echo "::group::Download File"
wget $LINK &>/dev/null
echo "::endgroup::"

echo "::group::Specify IMG"
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
echo "::endgroup::"

echo "::group::Unpack IMG"
wget -q https://raw.githubusercontent.com/DroidDumps/phoenix_firmware_dumper/main/utils/unpackboot.sh
bash unpackboot.sh $RECOVERYIMAGE unpacked
echo "::endgroup::"

echo "::group::Push To Github"
cd unpacked
git init
git remote add origin https://$GITHUB_ACTOR:$GH_TOKEN@github.com/${GITHUB_REPOSITORY}
git config --global user.email "raza231198@gmail.com"
git config --global user.name "MD Raza"
git add .
git commit -m "unpacked $VERSION" &>/dev/null
git checkout -b $VERSION
git push origin +$VERSION
echo "::endgroup::"
