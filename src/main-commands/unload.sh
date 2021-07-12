nvm deactivate >/dev/null 2>&1
unset -f nvm \
  nvm_iojs_prefix nvm_node_prefix \
  nvm_add_iojs_prefix nvm_strip_iojs_prefix \
  nvm_is_iojs_version nvm_is_alias nvm_has_non_aliased \
  nvm_ls_remote nvm_ls_remote_iojs nvm_ls_remote_index_tab \
  nvm_ls nvm_remote_version nvm_remote_versions \
  nvm_install_binary nvm_install_source nvm_clang_version \
  nvm_get_mirror nvm_get_download_slug nvm_download_artifact \
  nvm_install_npm_if_needed nvm_use_if_needed nvm_check_file_permissions \
  nvm_print_versions nvm_compute_checksum \
  nvm_get_checksum_binary \
  nvm_get_checksum_alg nvm_get_checksum nvm_compare_checksum \
  nvm_version nvm_rc_version nvm_match_version \
  nvm_ensure_default_set nvm_get_arch nvm_get_os \
  nvm_print_implicit_alias nvm_validate_implicit_alias \
  nvm_resolve_alias nvm_ls_current nvm_alias \
  nvm_binary_available nvm_change_path nvm_strip_path \
  nvm_num_version_groups nvm_format_version nvm_ensure_version_prefix \
  nvm_normalize_version nvm_is_valid_version \
  nvm_ensure_version_installed nvm_cache_dir \
  nvm_version_path nvm_alias_path nvm_version_dir \
  nvm_find_nvmrc nvm_find_up nvm_find_project_dir nvm_tree_contains_path \
  nvm_version_greater nvm_version_greater_than_or_equal_to \
  nvm_print_npm_version nvm_install_latest_npm nvm_npm_global_modules \
  nvm_has_system_node nvm_has_system_iojs \
  nvm_download nvm_get_latest nvm_has nvm_install_default_packages nvm_get_default_packages \
  nvm_curl_use_compression nvm_curl_version \
  nvm_auto nvm_supports_xz \
  nvm_echo nvm_err nvm_grep nvm_cd \
  nvm_die_on_prefix nvm_get_make_jobs nvm_get_minor_version \
  nvm_has_solaris_binary nvm_is_merged_node_version \
  nvm_is_natural_num nvm_is_version_installed \
  nvm_list_aliases nvm_make_alias nvm_print_alias_path \
  nvm_print_default_alias nvm_print_formatted_alias nvm_resolve_local_alias \
  nvm_sanitize_path nvm_has_colors nvm_process_parameters \
  nvm_node_version_has_solaris_binary nvm_iojs_version_has_solaris_binary \
  nvm_curl_libz_support nvm_command_info nvm_is_zsh nvm_stdout_is_terminal \
  nvm_npmrc_bad_news_bears \
  nvm_get_colors nvm_set_colors nvm_print_color_code nvm_format_help_message_colors \
  nvm_echo_with_colors nvm_err_with_colors \
  nvm_get_artifact_compression nvm_install_binary_extract \
  >/dev/null 2>&1
unset NVM_RC_VERSION NVM_NODEJS_ORG_MIRROR NVM_IOJS_ORG_MIRROR NVM_DIR \
  NVM_CD_FLAGS NVM_BIN NVM_INC NVM_MAKE_JOBS \
  NVM_COLORS INSTALLED_COLOR SYSTEM_COLOR \
  CURRENT_COLOR NOT_INSTALLED_COLOR DEFAULT_COLOR LTS_COLOR \
  >/dev/null 2>&1
