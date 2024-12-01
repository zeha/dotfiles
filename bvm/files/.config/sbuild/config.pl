# SOURCE: dotfiles/bvm
$chroot_mode = 'unshare';
$source_only_changes = 1;
$apt_update = 1;
$external_commands = { "build-failed-commands" => [ [ '%SBUILD_SHELL' ] ] };

$unshare_mmdebstrap_extra_args = {"*" => ["--aptopt='Acquire::http { Proxy \"http://127.0.0.1:3142\"; }'", "--include=auto-apt-proxy"]};
$unshare_mmdebstrap_keep_tarball = 1;
$unshare_mmdebstrap_max_age = 680400;
