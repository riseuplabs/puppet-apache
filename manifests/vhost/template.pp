# template_mode:
#   - php: for a default php application
#   - static: for a static application (default)
#   - perl: for a mod_perl application
#   - php_joomla: for a joomla application
#
# domainalias:
#   - absent: no domainalias is set (*default*)
#   - www: domainalias is set to www.$domain
#   - else: domainalias is set to that
#
# ssl_mode: wether this vhost supports ssl or not
#   - false: don't enable ssl for this vhost (default)
#   - true: enable ssl for this vhost
#   - force: enable ssl and redirect non-ssl to ssl
#
define apache::vhost::template(
    $ensure = present,
    $path = 'absent',
    $path_is_webdir = false,
    $domain = 'absent',
    $domainalias = 'absent',
    $server_admin = 'absent',
    $allow_override = 'None',
    $php_upload_tmp_dir = 'absent',
    $php_session_save_path = 'absent',
    $cgi_binpath = 'absent',
    $do_includes = false,
    $options = 'absent',
    $additional_options = 'absent',
    $default_charset = 'absent',
    $run_mode = 'normal',
    $run_uid = 'absent',
    $run_gid = 'absent',
    $template_mode = 'static',
    $ssl_mode = false,
    $mod_security = true,
    $htpasswd_file = 'absent',
    $htpasswd_path = 'absent',
    $ldap_auth = false,
    $ldap_user = 'any'
){
    $real_path = $path ? {
        'absent' => $operatingsystem ? {
            openbsd => "/var/www/htdocs/$name",
            default => "/var/www/vhosts/$name"
        },
        default => $path
    }

    if $path_is_webdir {
        $documentroot = "$real_path"
    } else {
        $documentroot = "$real_path/www"
    }
    $logdir = "$real_path/logs"

    $servername = $domain ? {
        'absent' => $name,
        default => $domain
    }
    $serveralias = $domainalias ? {
        'absent' => '',
        'www' => "www.${servername}",
        default => $domainalias
    }
    if $htpasswd_path == 'absent' {
      $real_htpasswd_path = "/var/www/htpasswds/$name"
    } else {
      $real_htpasswd_path = $htpasswd_path
    }
    case $run_mode {
        'itk': {
            case $run_uid {
                'absent': { fail("you have to define run_uid for $name on $fqdn") }
            }
            case $run_gid {
                'absent': { fail("you have to define run_gid for $name on $fqdn") }
            }
        }
    }

    # set default dirs for templates
    # php upload_tmp_dir
    case $php_upload_tmp_dir {
        'absent': {
            $real_php_upload_tmp_dir = "/var/www/upload_tmp_dir/$name"
        }
        default: { $real_php_upload_tmp_dir = $php_upload_tmp_dir }
    }
    # php session_save_path
    case $php_session_save_path {
        'absent': {
            $real_php_session_save_path = "/var/www/session.save_path/$name"
        }
        default: { $real_php_session_save_path = $php_session_save_path }
    }

    apache::vhost::file{$name:
        ensure => $ensure,
        content => template("apache/vhosts/$template_mode/$operatingsystem.erb"),
        do_includes => $do_includes,
        htpasswd_file => $htpasswd_file,
        htpasswd_path => $htpasswd_path,
    }
}
