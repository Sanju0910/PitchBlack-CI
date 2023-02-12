#!/bin/bash

printf "\e[1;32m \u2730 Recovery Compiler\e[0m\n\n"

# Source Configs
source $CONFIG

# Echo Loop
while ((${SECONDS_LEFT:=10} > 0)); do
    printf "Please wait %.fs ...\n" "${SECONDS_LEFT}"
    sleep 1
    SECONDS_LEFT=$((SECONDS_LEFT - 1))
done
unset SECONDS_LEFT

echo "::group::Mandatory Variables Checkup"
if [[ -z ${MANIFEST} ]]; then
    printf "Please Provide A Manifest URL with/without Branch\n"
    exit 1
fi
# Default TARGET will be recoveryimage if not provided
export TARGET=pbrp
# Default FLAVOR will be eng if not provided
export FLAVOR=${FLAVOR:-eng}
# Default TZ (Timezone) will be set as UTC if not provided
export TZ=${TZ:-UTC}
if [[ ! ${TZ} == "UTC" ]]; then
    sudo timedatectl set-timezone ${TZ}
fi
echo "::endgroup::"

printf "We are going to build ${FLAVOR}-flavored ${TARGET} for ${CODENAME} from the manufacturer ${VENDOR}\n"

# cd To An Absolute Path
mkdir -p ~/runner/builder &>/dev/null
cd ~ || exit 1

echo "::group::Source Repo Sync"
printf "Initializing Repo\n"
printf "We will be using %s for Manifest source\n" "${MANIFEST}"
repo init -q -u ${MANIFEST} --depth=1 --groups=all,-notdefault,-device,-darwin,-x86,-mips || { printf "Repo Initialization Failed.\n"; exit 1; }
repo sync -c -q --force-sync --no-clone-bundle --no-tags -j6 || { printf "Git-Repo Sync Failed.\n"; exit 1; }
echo "::endgroup::"

echo "::group::Device and Kernel Tree Cloning"
printf "Cloning Device Tree\n"
git clone ${DT_LINK} --depth=1 device/${VENDOR}/${CODENAME}
# omni.dependencies file is a must inside DT, otherwise lunch fails
[[ ! -f device/${VENDOR}/${CODENAME}/omni.dependencies ]] && printf "[\n]\n" > device/${VENDOR}/${CODENAME}/omni.dependencies
if [[ ! -z "${KERNEL_LINK}" ]]; then
    printf "Using Manual Kernel Compilation\n"
    git clone ${KERNEL_LINK} --depth=1 kernel/${VENDOR}/${CODENAME}
else
    printf "Using Prebuilt Kernel For The Build.\n"
fi
echo "::endgroup::"

echo "::group::Secret Bootable"
if [[ $USE_SECRET_BOOTABLE == 'true' ]] && [[ -z "$SECRET_BR" ]]; then
    printf "Secret Branch is Not Defined\n"
elif [[ $USE_SECRET_BOOTABLE == 'true' ]] && [[ ! -z "$SECRET_BR" ]]; then
    rm -rf bootable/recovery
    printf "Cloning Secret Bootable\n"
    git clone --quiet --progress https://pbrp-bot:$GH_BOT_TOKEN@github.com/PitchBlackRecoveryProject/pbrp_recovery_secrets -b ${SECRET_BR} --single-branch bootable/recovery
else
    printf "Using Default Bootable\n"
fi
echo "::endgroup::"

echo "::group::Extra Commands"
if [[ ! -z "$EXTRA_CMD" ]]; then
    printf "Executing Extra Commands\n"
    eval "${EXTRA_CMD}" || { printf "Failed While Executing Extra Commands.\n"; exit 1; }
    cd /home/runner/builder || exit
fi
echo "::endgroup::"

echo "::group::Pre-Compilation"
printf "Compiling Recovery...\n"
export ALLOW_MISSING_DEPENDENCIES=true

# Only for (Unofficial) TWRP Building...
# If lunch throws error for roomservice, saying like `device tree not found` or `fetching device already present`,
# replace the `roomservice.py` with appropriate one according to platform version from here
# >> https://gist.github.com/rokibhasansagar/247ddd4ef00dcc9d3340397322051e6a/
# and then `source` and `lunch` again

source build/envsetup.sh
lunch omni_${CODENAME}-${FLAVOR} || { printf "Compilation failed.\n"; exit 1; }
echo "::endgroup::"

echo "::group::Compilation"
mka -j 2 ${TARGET} || { printf "Compilation failed.\n "; free -h; exit 1; }
echo "::endgroup::"

# Export VENDOR, CODENAME and BuildPath for next steps
echo "VENDOR=${VENDOR}" >> ${CIRRUS_ENV}
echo "CODENAME=${CODENAME}" >> ${CIRRUS_ENV}
echo "BuildPath=~/runner/builder" >> ${CIRRUS_ENV}

# TODO:: Add GitHub Release Script Here
