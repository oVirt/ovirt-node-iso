#!/bin/bash -ex
# oVirt node iso jenkins build script
#
# Copyright (C) 2008 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

## Make sure WORKSPACE is not empty
WORKSPACE="${WORKSPACE?No WORKSPACE env var, are you running in jenkins?}"
BUILD_NUMBER="${BUILD_NUMBER?No BUILD_NUMBER env var, are you running in jenkins?}"
JOB_URL="${JOB_URL?No JOB_URL env var, are you running in jenkins?}"
MANIFEST_LOG="${WORKSPACE}/ovirt-node-iso.mini-manifest.txt"
OVIRT_CACHE_DIR="${WORKSPACE}/ovirt-cache"
OVIRT_LOCAL_REPO="file://${OVIRT_CACHE_DIR}/ovirt"
BUILD_TYPE="${BUILD_TYPE:-STABLE}"
export HOME="${WORKSPACE}"
export OVIRT_CACHE_DIR OVIRT_LOCAL_REPO
## Avoid non matching globs from getting printed
shopt -s nullglob

log() {
    echo "$@" >> "$MANIFEST_LOG"
}

pre_cleanup()
{
    [[ -f Makefile ]] && make -k distclean
    rm -rf "${WORKSPACE}"/ovirt-node-tools \
        "${WORKSPACE}"/*iso \
        "${WORKSPACE}"/rpmbuild \
        "${WORKSPACE}"/manifest* \
        "${WORKSPACE}"/old_artifacts \
        "${WORKSPACE}"/ovirt-node-recipe

}

post_cleanup()
{
    [[ -f Makefile ]] && make -k distclean
    rm -rf \
        "$WORKSPACE/rpmbuild" \
        "$WORKSPACE/autom4te.cache" \
        "$WORKSPACE/gluster-3.4" \
        "$WORKSPACE/local" \
        "$WORKSPACE/node-stable-repo" \
        "$WORKSPACE/ovirt-cache" \
        "$WORKSPACE/ovirt-node-recipe" \
        "$WORKSPACE/ovirt-node-tools" \
        "$WORKSPACE/*iso" \
        "$WORKSPACE/old_artifacts" \
        "$WORKSPACE/epel" \
        "$WORKSPACE/centos" \
        "$WORKSPACE/centos-updates"
}

get_recipe()
{
    local cache_dir=${1:?}
    local -a recipes tools
    recipes=("${OVIRT_CACHE_DIR}"/ovirt/noarch/ovirt-node-recipe*rpm)
    tools=("${OVIRT_CACHE_DIR}"/ovirt/noarch/ovirt-node-tools*rpm)
    if [[ -n $recipes ]]; then
        echo -n "ovirt-node-recipe"
    elif [[ -n $tools ]]; then
        echo -n "ovirt-node-tools"
    else
        return 4
    fi
}

extract_recipes()
{
    local recipe_dir="${1?}"
    local recipe_rpm="${2?}"
    # ovirt-node recipe rpm should be copied to ${OVIRT_CACHE_DIR}/ovirt/noarch
    mkdir "${recipe_dir}"
    pushd "${recipe_dir}" &>/dev/null
    rpm2cpio "${recipe_rpm}" | pax -r
    popd &>/dev/null
    return 0
}

generate_iso()
{
    local recipes_dir="${1?}"
    local custom_build_number="${2?}"
    ./autogen.sh --with-recipe="${recipes_dir}" \
                 --with-build-number="${custom_build_number}"
    ## add the repo-creator to the path
    PATH="$PATH:${recipes_dir}/../../sbin"
    sudo -E env PATH=$PATH make BUILD_TYPE="$BUILD_TYPE" iso \
        1>make.stdout.log 2>make.stderr.log
    ## restore any file permissions
    sudo -E chown -R $USER:$USER .
}

get_manifests_from_iso()
{
    local iso_file="${1?}"
    local dst_dir="${2?}"
    # Get iso details
    iso_dir=$(mktemp -d)
    sudo mount -o loop "${iso_file}" "$iso_dir"
    cp "$iso_dir"/isolinux/manifest-srpm.txt \
       "$iso_dir"/isolinux/manifest-rpm.txt \
       "$iso_dir"/isolinux/manifest-file.txt.bz2 \
       "${dst_dir}"
    chmod 666 "${dst_dir}"/manifest-*txt*
    sudo umount "${iso_dir}"
    rmdir "${iso_dir}"
}

get_old_artifacts()
{
    local dst_dir="${1?}"
    [[ -e "$dst_dir" ]] && rm -rf "$dst_dir"
    mkdir -p "$dst_dir"
    pushd "$dst_dir" &>/dev/null
    wget "${JOB_URL}/lastSuccessfulBuild/artifact/*zip*/archive.zip" \
    || return 1
    unzip archive.zip
    popd &>/dev/null
}


write_build_info()
{
    local recipe_name="${1?}"
    local recipe_rpm="${2}"
    local iso_file size human_size old_size old_human_size
    ## get iso details
    iso_file="${WORKSPACE}/$(make verrel).iso"
    get_manifests_from_iso "$iso_file" "$WORKSPACE"
    egrep '^kernel|kvm|libvirt|^vdsm|^ovirt-node|^fence-agents' manifest-srpm.txt \
    | sed 's/\.src\.rpm//' > "$MANIFEST_LOG"

    log "======================================================"
    log "${recipe_name} used:    ${recipe_rpm##*/} "

    # Check size of iso and report in mini-manifest.txt
    log "======================================================"
    size=$(du -k ${iso_file})
    human_size=$(du -h ${iso_file})
    log "    Iso Size:  ${size%%	*}  (${human_size%%	*})"

    old_size=""
    old_human_size=""
    if true; then #get_old_artifacts "$WORKSPACE/old_artifacts"; then
        old_isos=("${WORKSPACE}"/old_artifacts/archive/ovirt-node-iso*iso)
        old_iso="${old_isos[0]}"
        if [[ -e "$old_iso" ]]; then
            old_size=$(du -k "$old_iso")
            old_human_size=$(du -h "$old_iso")
            log "Old Iso Size:  ${old_size%%	*}  (${old_human_size%%	*})"
        else
            log "No old iso found for compairson"
        fi
    else
        log "No previous build archive found for old iso compairson"
    fi
    # md5 and sha256sums
    md5="$(md5sum ${iso_file})"
    sha="$(sha256sum ${iso_file})"
    log "MD5SUM:  ${md5%% *}"
    log "SHA256SUM:  ${sha%% *}"
    log "======================================================"
    log "livecd-tools version:  $(rpm -qa livecd-tools)"
}

gather_artifacts()
{
    local dst_dir
    dst_dir="$WORKSPACE/exported-artifacts"
    [[ -e "$dst_dir" ]] && rm -rf "$dst_dir"
    mkdir -p "$dst_dir"
    mv "$WORKSPACE/ovirt-cache/ovirt/noarch/scm_hash.txt" \
        "$dst_dir/ovirt-node_scm_hash.txt"
    cp "$WORKSPACE/.git/HEAD" "$dst_dir/scm_hash.txt"
    to_archive=(
        "$WORKSPACE"/ovirt-node-*iso
        "$WORKSPACE"/ovirt-cache/ovirt/*/ovirt-node-*rpm
        "$WORKSPACE"/manifest*
        "$WORKSPACE"/ovirt-node-iso.mini-manifest.txt
        "$WORKSPACE"/*log
    )
    mv "${to_archive[@]}" "$dst_dir"
}


################## MAIN
## Make sure we are in that WORKSPACE
cd "$WORKSPACE"

## And that we don't have old files
pre_cleanup

recipe=$(get_recipe $OVIRT_CACHE_DIR)
if [[ $? -ne 0 ]]; then
    echo "ERROR: no recipe rpm found"
    exit 4
fi

recipe_rpms=("${OVIRT_CACHE_DIR}/ovirt/noarch/${recipe}"*)
## get only the first one
recipe_rpm="${recipe_rpms[0]}"
[[ -f "$recipe_rpm" ]] \
|| {
    echo "Unable to find previous build rpms at" \
         "${OVIRT_CACHE_DIR}/ovirt/noarch/${recipe}"
    exit 1
}
## get the info from the rpm
read -r recipe_name recipe_version recipe_release <<<$(
    rpm -qp \
        --queryformat "%{name}\n%{version}\n%{release}" \
        "$recipe_rpm"
)
recipe_build_number="${recipe_release%.*}"
recipe_build_number="${recipe_build_number#*.}"
if [[ "$recipe_build_number" == "$release" ]]; then
    recipe_build_number=""
fi

extract_recipes "${WORKSPACE}/${recipe_name}" "$recipe_rpm"

## prepare repo
createrepo "${OVIRT_CACHE_DIR}"/ovirt

recipes_dir="${WORKSPACE}/${recipe_name}/usr/share/${recipe_name}"
generate_iso "$recipes_dir" "${recipe_build_number}${BUILD_NUMBER}"

write_build_info  "$recipe_name" "$recipe_rpm"

gather_artifacts

## free space in the slave
post_cleanup
