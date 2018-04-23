# connect with puppet server
ssh root@puppetserver.mshome.net

# puppet server is running
systemctl status pe-puppetserver.service

# signing configuration
cat /etc/puppetlabs/puppet/puppet.conf

# installed modules
puppet module list

# install puppet dsc-lite module
# puppet module install puppetlabs-dsc_lite

# in case of bad internet
cp -r ~/reboot/ /etc/puppetlabs/code/environments/production/modules/
cp -r ~/dsc_lite/ /etc/puppetlabs/code/environments/production/modules/

puppet module list

# generate a new modulep
puppet module generate --skip-interview bg-dscpsconfeu
tree dscpsconfeu

# add puppet class to init.pp
cat > ./dscpsconfeu/manifests/init.pp <<EOF
class dscpsconfeu () {
    dsc { 'dockerdsc' :
        dsc_resource_name   => 'script',
        dsc_resource_module => {
            name    => 'PSDesiredStateConfiguration',
            version => '1.1'
        },
        dsc_resource_properties  => {
            getscript => '
                @{}
            ',
            setscript => '
                Write-Verbose -Message "Executing SetScript"
                Install-Module -Name dockerdsc -Force
            ',
            testscript => '
                Write-Verbose -Message "Executing TestScript"
                if (\$null -eq (Get-Module -ListAvailable -Name dockerdsc)) {
                    \$false
                } else {
                    \$true
                }
            ',
        },
    }

    dsc { 'containersfeature' :
        dsc_resource_name   => 'WindowsFeature',
        dsc_resource_module => {
            name    => 'PSDesiredStateConfiguration',
            version => '1.1'
        },
        dsc_resource_properties  => {
            ensure => 'present',
            name => 'Containers'
        },
    }

    reboot { 'dsc_reboot' :
        message => 'DSC has requested a reboot',
        when => 'pending'
    }

    dsc { 'dockerbin' :
        dsc_resource_name   => 'archive',
        dsc_resource_module => {
            name    => 'PSDesiredStateConfiguration',
            version => '1.1'
        },
        dsc_resource_properties  => {
            ensure => 'present',
            path => 'C:\\Windows\\TEMP\\docker.zip',
            destination => 'C:\\Program Files'
        },
    }

    dsc { 'dockerenv' :
        dsc_resource_name   => 'Environment',
        dsc_resource_module => {
            name    => 'PSDesiredStateConfiguration',
            version => '1.1'
        },
        dsc_resource_properties  => {
            path => true,
            name => 'Path',
            value => 'C:\\Program Files\\Docker'
        },
    }

    dsc { 'dockersvcregister' :
        dsc_resource_name   => 'DockerService',
        dsc_resource_module => {
            name    => 'DockerDsc',
            version => '0.0.0.2'
        },
        dsc_resource_properties  => {
            ensure => 'Present',
            path => 'C:\\Program Files\\Docker'
        },
        require => [
            Dsc['containersfeature'],
            Dsc['dockerdsc'],
            Dsc['dockerbin']
        ],
    }

    Service { 'docker' :
        ensure => 'running',
        enable => true,
        require => Dsc['dockersvcregister'],
    }

    File { ['C:\\ProgramData\\docker', 'C:\\ProgramData\\docker\\config'] :
        ensure => 'directory',
    }

    File { 'C:\\ProgramData\\docker\\config\\daemon.json' :
        content => '
        {
            "hosts": ["tcp://0.0.0.0:2375"]
        }',
        notify => Service['docker'],
        require => [
            File['C:\\ProgramData\\docker'],
            File['C:\\ProgramData\\docker\\config'],
            Dsc['dockersvcregister'],
        ]
    }
}
EOF

# remove dependencies and prefix from metadata manifest
vi ./dscpsconfeu/metadata.json

# install custom puppet module
mv dscpsconfeu/ /etc/puppetlabs/code/environments/production/modules/
puppet module list

# assign configuration to node
cat >> /etc/puppetlabs/code/environments/production/manifests/site.pp <<EOL
node puppetclient.mshome.net {
  class { 'dscpsconfeu': }
}
EOL

cat /etc/puppetlabs/code/environments/production/manifests/site.pp