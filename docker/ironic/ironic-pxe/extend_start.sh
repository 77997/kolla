#!/bin/bash


# For x86 legacy BIOS boot mode
function prepare_pxe_pxelinux {
    if [[ "${KOLLA_BASE_DISTRO}" =~ debian|ubuntu ]]; then
        cp /usr/lib/PXELINUX/pxelinux.0 \
           /usr/lib/syslinux/modules/bios/{chain.c32,ldlinux.c32} \
           ${TFTPBOOT_PATH}/
    elif [[ "${KOLLA_BASE_DISTRO}" =~ centos|rocky ]]; then
        if [[ "${TFTPBOOT_PATH}" != /tftpboot ]]; then
            cp /tftpboot/{pxelinux.0,chain.c32,ldlinux.c32} \
               ${TFTPBOOT_PATH}/
        fi
    fi
}

# For UEFI boot mode -- copy boot files for all available target architectures
function prepare_pxe_grub {
    if [[ "${KOLLA_BASE_DISTRO}" =~ debian|ubuntu ]]; then
        # Copy x86_64 UEFI boot files if available
        if [[ -f /usr/lib/shim/shimx64.efi.signed ]]; then
            cp /usr/lib/shim/shimx64.efi.signed ${TFTPBOOT_PATH}/bootx64.efi
            cp /usr/lib/grub/x86_64-efi-signed/grubnetx64.efi.signed ${TFTPBOOT_PATH}/grubx64.efi
        fi
        # Copy aarch64 UEFI boot files if available
        if [[ -f /usr/lib/shim/shimaa64.efi.signed ]]; then
            cp /usr/lib/shim/shimaa64.efi.signed ${TFTPBOOT_PATH}/bootaa64.efi
            cp /usr/lib/grub/arm64-efi-signed/grubnetaa64.efi.signed ${TFTPBOOT_PATH}/grubaa64.efi
        fi
    elif [[ "${KOLLA_BASE_DISTRO}" =~ centos|rocky ]]; then
        # RPM: both x64 and aa64 packages are installed
        if [[ -f /boot/efi/EFI/${KOLLA_BASE_DISTRO}/shimx64.efi ]]; then
            cp /boot/efi/EFI/${KOLLA_BASE_DISTRO}/shimx64.efi ${TFTPBOOT_PATH}/bootx64.efi
            cp /boot/efi/EFI/${KOLLA_BASE_DISTRO}/grubx64.efi ${TFTPBOOT_PATH}/grubx64.efi
        fi
        if [[ -f /boot/efi/EFI/${KOLLA_BASE_DISTRO}/shimaa64.efi ]]; then
            cp /boot/efi/EFI/${KOLLA_BASE_DISTRO}/shimaa64.efi ${TFTPBOOT_PATH}/bootaa64.efi
            cp /boot/efi/EFI/${KOLLA_BASE_DISTRO}/grubaa64.efi ${TFTPBOOT_PATH}/grubaa64.efi
        fi
    fi
}

function prepare_ipxe {
    # NOTE(mgoddard): Ironic uses snponly.efi as the default for
    # uefi_ipxe_bootfile_name since Xena. In Wallaby and earlier releases it
    # was ipxe.efi. Ensure that both exist, using symlinks where the files are
    # named differently to allow the original names to be used in ironic.conf.
    if [[ "${KOLLA_BASE_DISTRO}" =~ debian|ubuntu ]]; then
        # NOTE(m-anson): ipxe-arm64.efi is not symlinked from /boot to
        # /usr/lib/ipxe by the Ubuntu ipxe package, so fix that here.
        if [[ -e /boot/ipxe-arm64.efi ]]; then
            ln -s /boot/ipxe-arm64.efi /usr/lib/ipxe/
        fi
        cp /usr/lib/ipxe/{undionly.kpxe,ipxe*.efi,snponly.efi} ${TFTPBOOT_PATH}/
    elif [[ "${KOLLA_BASE_DISTRO}" =~ centos|rocky ]]; then
        cp /usr/share/ipxe/{undionly.kpxe,ipxe-snponly-x86_64.efi} ${TFTPBOOT_PATH}/
        cp /usr/share/ipxe/arm64-efi/snponly.efi ${TFTPBOOT_PATH}/ipxe-snponly-aarch64.efi
        if [[ ! -e ${TFTPBOOT_PATH}/snponly.efi ]]; then
            ln -s ${TFTPBOOT_PATH}/ipxe-snponly-${KOLLA_BASE_ARCH}.efi ${TFTPBOOT_PATH}/snponly.efi
        fi
    fi
}

function prepare_esp_image {
    # NOTE(bbezak): based on https://docs.openstack.org/ironic/2024.2/install/configure-esp.html
    # ESP image needs to be provided for UEFI boot with virtual media:
    # https://docs.openstack.org/ironic/2024.2/admin/drivers/redfish.html#virtual-media-boot
    # UEFI uses distinct filenames per arch (BOOTx64.EFI vs BOOTAA64.EFI),
    # so a single FAT image can hold boot files for all target architectures.
    DEST=${HTTPBOOT_PATH}/esp.img
    dd if=/dev/zero of=$DEST bs=4096 count=2048
    mkfs.msdos -F 12 -n ESP_IMAGE $DEST
    mmd -i $DEST EFI EFI/BOOT

    if [[ "${KOLLA_BASE_DISTRO}" =~ debian|ubuntu ]]; then
        if [[ -f /usr/lib/shim/shimx64.efi.signed ]]; then
            mcopy -i $DEST -v /usr/lib/shim/shimx64.efi.signed ::EFI/BOOT/bootx64.efi
            mcopy -i $DEST -v /usr/lib/grub/x86_64-efi-signed/grubnetx64.efi.signed ::EFI/BOOT/grubx64.efi
        fi
        if [[ -f /usr/lib/shim/shimaa64.efi.signed ]]; then
            mcopy -i $DEST -v /usr/lib/shim/shimaa64.efi.signed ::EFI/BOOT/bootaa64.efi
            mcopy -i $DEST -v /usr/lib/grub/arm64-efi-signed/grubnetaa64.efi.signed ::EFI/BOOT/grubaa64.efi
        fi
    elif [[ "${KOLLA_BASE_DISTRO}" =~ centos|rocky ]]; then
        if [[ -f /boot/efi/EFI/${KOLLA_BASE_DISTRO}/shimx64.efi ]]; then
            mcopy -i $DEST -v /boot/efi/EFI/${KOLLA_BASE_DISTRO}/shimx64.efi ::EFI/BOOT/bootx64.efi
            mcopy -i $DEST -v /boot/efi/EFI/${KOLLA_BASE_DISTRO}/grubx64.efi ::EFI/BOOT/grubx64.efi
        fi
        if [[ -f /boot/efi/EFI/${KOLLA_BASE_DISTRO}/shimaa64.efi ]]; then
            mcopy -i $DEST -v /boot/efi/EFI/${KOLLA_BASE_DISTRO}/shimaa64.efi ::EFI/BOOT/bootaa64.efi
            mcopy -i $DEST -v /boot/efi/EFI/${KOLLA_BASE_DISTRO}/grubaa64.efi ::EFI/BOOT/grubaa64.efi
        fi
    fi

    mdir -i $DEST ::EFI/BOOT
}

# Bootstrap and exit if KOLLA_BOOTSTRAP variable is set. This catches all cases
# of the KOLLA_BOOTSTRAP variable being set, including empty.
if [[ "${!KOLLA_BOOTSTRAP[@]}" ]]; then
    mkdir -p ${TFTPBOOT_PATH} ${HTTPBOOT_PATH}
    chown ironic: ${TFTPBOOT_PATH} ${HTTPBOOT_PATH}
    prepare_pxe_pxelinux
    prepare_pxe_grub
    prepare_ipxe
    prepare_esp_image
    exit 0
fi

# Template out a TFTP map file, using the TFTPBOOT_PATH variable.
envsubst < /map-file-template > /map-file

. /usr/local/bin/kolla_httpd_setup
