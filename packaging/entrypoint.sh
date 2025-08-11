#!/usr/bin/env bash

set -e
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

pull_addons_from_urls(){
  EXTRA_ADDONS_URLS_TO_PULL=$1
  EXTRA_ADDONS_PULLED_DIR=$2
  IFS=",";
  for addon_pull_url in $EXTRA_ADDONS_URLS_TO_PULL; do
    if [[ $addon_pull_url == "git://"* ]]; then
      package_value=${addon_pull_url#"git://"}
      branch_name=${package_value%%"//"*}
      git_address=${package_value#*"//"}
      repo_name=$(basename $git_address)
      repo_name=${repo_name%.*}

      if ! [ -d $EXTRA_ADDONS_PULLED_DIR/$repo_name ]; then
        git clone --depth 1 -b ${branch_name} ${git_address} $EXTRA_ADDONS_PULLED_DIR/$repo_name
      fi
      if [ -f $EXTRA_ADDONS_PULLED_DIR/$repo_name/requirements.txt ]; then
        # The following command should not fail even if requirements cannot be installed. In airgapped networks for example.
        pip install -f $EXTRA_ADDONS_PULLED_DIR/$repo_name/requirements.txt || true
      fi
    # elif [[ ${PACKAGES_VALUES[i]} == "file://"* ]]; then
    # TBD: Define other prefixes.
    fi
  done
  unset IFS
}

set_addons_dir_env(){
  EXTRA_ADDONS_PATH=$1
  EXTRA_ADDONS_PULLED_DIR=$2

  shopt -s nullglob
  for dir in $EXTRA_ADDONS_PATH/*/; do
    if [ -n "$ODOO_ADDONS_DIR" ]; then ODOO_ADDONS_DIR="${ODOO_ADDONS_DIR},"; fi  # Adds comma if the list not already empty
    ODOO_ADDONS_DIR="${ODOO_ADDONS_DIR}${dir%/}"
  done

  if [ -n "$EXTRA_ADDONS_PULLED_DIR" ] && [ -d "$EXTRA_ADDONS_PULLED_DIR" ]; then
    for dir in $EXTRA_ADDONS_PULLED_DIR/*/; do
      if [ -n "$ODOO_ADDONS_DIR" ]; then ODOO_ADDONS_DIR="${ODOO_ADDONS_DIR},"; fi  # Adds comma if the list not already empty
      ODOO_ADDONS_DIR="${ODOO_ADDONS_DIR}${dir%/}"
    done
  fi
  shopt -u nullglob
  export ODOO_ADDONS_DIR
}

generate_final_addons_dir_env(){
  # Multiple Addons directories are possible in this:
  # - /usr/lib/python3/dist-packages/odoo/addons - Odoo's Base addons. These will be automatically considered when odoo starts.
  # - /bitnami/odoo/data/addons - Addons inside data directory. These will be automatically considered when odoo starts.
  # - /opt/odoo/extraddons/*/ - These are pacakaged during build time.
  # - /bitnami/odoo/extraaddons/*/ - These are pulled when the docker starts for the first time. See EXTRA_ADDONS_URLS_TO_PULL env below.

  # EXTRA_ADDONS_URLS_TO_PULL env var is optional.
  #     These urls will be pulled during runtime (if the directories are not already present).
  #     Multiple urls are supported, seperated by comma.
  #     Should be given in the form of
  #         git://branch-name//https://github.com/example/example,git://tag-name//https://token@github.com/example/example-private
  # ODOO_VOLUME_DIR env var is required
  # ODOO_ADDONS_DIR env var is optional.
  #     Any addons directories, other than the ones mentioned above, can be set through this variable from the outside.
  #     Addons directories mentioned in this env will be clubbed with the ones mentioned above to generate final list of addons dirs.

  if [ -n "$EXTRA_ADDONS_URLS_TO_PULL" ]; then
    ODOO_VOLUME_DIR=${ODOO_VOLUME_DIR:-/bitnami/odoo}
    ODOO_VOLUME_DIR=${ODOO_VOLUME_DIR%/}
    EXTRA_ADDONS_PULLED_DIR=${ODOO_VOLUME_DIR}/extraaddons
    mkdir -p $EXTRA_ADDONS_PULLED_DIR
    pull_addons_from_urls "$EXTRA_ADDONS_URLS_TO_PULL" "$EXTRA_ADDONS_PULLED_DIR"
  fi

  EXTRA_ADDONS_DIR=${EXTRA_ADDONS_DIR:-/opt/odoo/extraaddons}
  EXTRA_ADDONS_DIR=${EXTRA_ADDONS_DIR%/}
  set_addons_dir_env "$EXTRA_ADDONS_DIR" "$EXTRA_ADDONS_PULLED_DIR"
}

set_default_env_vars(){
  export ODOO_VOLUME_DIR=${ODOO_VOLUME_DIR:-/bitnami/odoo}
  export ODOO_VOLUME_DIR=${ODOO_VOLUME_DIR%/}
  export ODOO_DATA_DIR=${ODOO_DATA_DIR:-${ODOO_VOLUME_DIR}/data}
  # export ODOO_ADDONS_DIR="" # This will be set by set_addons_dir_env command 
  export ODOO_PASSWORD=${ODOO_PASSWORD:-admin}

  export ODOO_DATABASE_MAXCONN=${ODOO_DATABASE_MAXCONN:-64}
  export ODOO_DATABASE_SSLMODE=${ODOO_DATABASE_SSLMODE:-prefer}
  export ODOO_DATABASE_TEMPLATE=${ODOO_DATABASE_TEMPLATE:-template1}
  export ODOO_DATABASE_FILTER_OVERRIDE=${ODOO_DATABASE_FILTER_OVERRIDE:-^${ODOO_DATABASE_NAME}$}
}

generate_final_addons_dir_env  # Important to run this before set_default_env_vars because names are same.
set_default_env_vars

if [ -f "${ODOO_RC}.tpl" ]; then
  envsubst < ${ODOO_RC}.tpl > ${ODOO_RC}
fi

ADDL_ARGS=()

if [[ "$ODOO_SKIP_BOOTSTRAP" == "no" ]]; then
  ADDL_ARGS+=("-i" "$ODOO_BOOTSTRAP_MODULES")
fi
if [[ "$ODOO_SKIP_MODULES_UPDATE" == "no" ]]; then
  ODOO_UPDATE_MODULES=${ODOO_UPDATE_MODULES:-all}
  ADDL_ARGS+=("-u" "$ODOO_UPDATE_MODULES")
fi

exec $@ ${ADDL_ARGS[@]}
