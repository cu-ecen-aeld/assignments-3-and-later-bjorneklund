#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

if [ ! -d ${OUTDIR} ]; then
    echo "Could not create  ${OUTDIR}"
    exit
fi

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    make ARCH=${ARCH} CROSS_COMPILE="${CROSS_COMPILE}" mrproper
    make ARCH=${ARCH} CROSS_COMPILE="${CROSS_COMPILE}" defconfig 
    make -j4 ARCH=${ARCH} CROSS_COMPILE="${CROSS_COMPILE}" all
   # make ARCH=${ARCH} CROSS_COMPILE="${CROSS_COMPILE}" modules
    make -j4 ARCH=${ARCH} CROSS_COMPILE="${CROSS_COMPILE}" dtbs
fi

#echo "Adding the Image in outdir"
#cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image "$(OUTDIR)/."


echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"

if [ ! -e Image ]; then
    echo "Symlinking the Image in outdir"
    ln -s ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image Image
fi

FILE_SYSTEM="${OUTDIR}/rootfs"

if [ -d "${FILE_SYSTEM}" ]
then
	echo "Deleting rootfs directory at ${FILE_SYSTEM} and starting over"
    sudo rm  -rf ${FILE_SYSTEM}
fi

# TODO: Create necessary base directories
mkdir $FILE_SYSTEM
cd $FILE_SYSTEM
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log



cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make defconfig
    
else
    cd busybox
fi

# TODO: Make and install busybox
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${FILE_SYSTEM} ARCH=${ARCH} CROSS_COMPILE="${CROSS_COMPILE}" install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a "${FILE_SYSTEM}/bin/busybox" | grep "program interpreter"
${CROSS_COMPILE}readelf -a "${FILE_SYSTEM}/bin/busybox" | grep "Shared library"

# TODO: Add library dependencies to rootfs
TOOL_CHAIN_PATH="${HOME}/ToolChains/aarch64/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu"
cp "${TOOL_CHAIN_PATH}/libc/lib/ld-linux-aarch64.so.1" ${FILE_SYSTEM}/lib/.
cp "${TOOL_CHAIN_PATH}/libc/lib64/libm.so.6" ${FILE_SYSTEM}/lib64/.
cp "${TOOL_CHAIN_PATH}/libc/lib64/libresolv.so.2" ${FILE_SYSTEM}/lib64/.
cp "${TOOL_CHAIN_PATH}/libc/lib64/libc.so.6" ${FILE_SYSTEM}/lib64/.

# TODO: Make device nodes
sudo mknod -m 666 ${FILE_SYSTEM}/dev/null c 1 3
sudo mknod -m 666 ${FILE_SYSTEM}/dev/stdout c 5 1

# TODO: Clean and build the writer utility
FINDER_APP_PATH="${HOME}/Projects/assignment1/assignment-1-bjorneklund/finder-app"
cd $FINDER_APP_PATH

make clean
make CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
cp writer finder.sh finder-test.sh writer.sh autorun-qemu.sh "${FILE_SYSTEM}/home/."

cp -R ../conf "${FILE_SYSTEM}/home/."

# on the target rootfs
cd $FILE_SYSTEM
echo "root:x:0:0:root:/root:/bin/sh" > "${FILE_SYSTEM}/etc/passwd"
echo "root:x:0:" > "${FILE_SYSTEM}/etc/group"


# TODO: Chown the root directory
find . | cpio -H newc -ov --owner root:root > "${OUTDIR}/initramfs.cpio"

# TODO: Create initramfs.cpio.gz
gzip -f "${OUTDIR}/initramfs.cpio"