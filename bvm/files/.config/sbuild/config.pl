# SOURCE: dotfiles/bvm
$chroot_mode = 'unshare';
$external_commands = { "build-failed-commands" => [ [ '%SBUILD_SHELL' ] ] };
$source_only_changes = 1;
#$apt_update = 0;

$run_autopkgtest = 1;
#$autopkgtest_opts = [ '--apt-upgrade', '--', 'podman', 'localhost/autopkgtest/systemd/debian:%r'];
#$autopkgtest_opts = [ '--apt-upgrade', '--', 'unshare', '--release', '%r', '--arch', '%a' ];

#$run_piuparts = 1;
#$piuparts_root_args = ['PATH=/usr/sbin:/usr/bin:/sbin:/bin', 'unshare', '--pid', '--fork', '--mount-proc', '--map-root-user', '--map-auto'];
#$piuparts_opts = ["--basetgz=$HOME/.cache/sbuild/%r-%a.tar.zst", '--fake-essential-packages=systemd-sysv', '--distribution=%r'];

#$unshare_mmdebstrap_extra_args = {"*" => ["--aptopt='Acquire::http { Proxy \"http://127.0.0.1:3142\"; }'", "--include=auto-apt-proxy"]};

$unshare_mmdebstrap_extra_args = $conf->_get('UNSHARE_MMDEBSTRAP_EXTRA_ARGS');
push @{$unshare_mmdebstrap_extra_args}, "*", ['--aptopt=Acquire::http { Proxy "http://127.0.0.1:3142"; }', "--include=netbase"];

$unshare_mmdebstrap_distro_mangle = $conf->_get('UNSHARE_MMDEBSTRAP_DISTRO_MANGLE');
push @{$unshare_mmdebstrap_distro_mangle}, qr/^grml-.*$/ => 'unstable';
push @{$unshare_mmdebstrap_distro_mangle}, qr/^(.*)-backports$/ => '$1';
push @{$unshare_mmdebstrap_distro_mangle}, qr/^experimental/ => 'unstable';

$unshare_mmdebstrap_keep_tarball = 1;
$unshare_mmdebstrap_max_age = 680400;
