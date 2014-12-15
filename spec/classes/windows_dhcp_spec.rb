require 'spec_helper'

credentials = "
\$pass = convertto-securestring -String \"q1w2e3\" -AsPlainText -Force;
\$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist \"CONTOSO\\dhcp_admin\",\$pass
"

add_user_to_group_hash = {
    :command  => "net localgroup \"DHCP Administrators\" /ADD CONTOSO\\dhcp_admin",
    :unless   => "if ($(net localgroup \"DHCP Administrators\") -contains \"CONTOSO\\dhcp_admin\") { exit 0 } else { exit 1 }",
    :provider => 'powershell',
}

describe 'windows_dhcp', :type => :class do
  let(:default_params) {{
    :domain_user => 'CONTOSO\dhcp_admin',
    :domain_pass => 'q1w2e3',
  }}

  context 'on Windows' do
    let(:params) do default_params end
    let(:facts) {{
      :fqdn            => 'DHCPSERVER.CONTOSO.LOCAL',
      :kernelversion   => '6.2',
      :osfamily        => 'Windows',
      :operatingsystem => 'Windows',
    }}

    describe 'with only required parameters ($domain_user and $domain_pass)' do
      it { should compile.with_all_deps }

      it { should contain_class('windows_dhcp::install').that_comes_before('windows_dhcp::config') }
      it { should contain_class('windows_dhcp::config') }
      it { should contain_class('windows_dhcp::service').that_subscribes_to('windows_dhcp::config') }
      it { should contain_class('windows_dhcp::service').that_comes_before('windows_dhcp') }
      it { should contain_class('windows_dhcp') }

      # windows_dhcp::install
      it { should contain_windowsfeature('dhcp').with_ensure('present') }

      # windows_dhcp::config
      it { should contain_exec('add DHCP security groups').with({
        :command  => 'Add-DhcpServerSecurityGroup',
        :unless   => "if ($(net localgroup) -contains '*DHCP Administrators') { exit 0 } else { exit 1 }",
        :provider => 'powershell',
      })}
      it { should contain_exec('add DHCP security groups').that_comes_before('exec[add CONTOSO\dhcp_admin to "DHCP Administrators"]') }

      it { should contain_exec('add CONTOSO\dhcp_admin to "DHCP Administrators"').with(add_user_to_group_hash) }
      it { should contain_exec('add CONTOSO\dhcp_admin to "DHCP Administrators"').that_comes_before('exec[authorise server]') }

      it { should contain_exec('authorise server').with({
        :command  => "#{credentials}; saps powershell.exe -Credential \$cred -NoNewWindow -ArgumentList \"Add-DhcpServerInDC\"",
        :unless   => "if ((Get-DhcpServerInDC).DnsName -contains \"DHCPSERVER.CONTOSO.LOCAL\") { exit 0 } else { exit 1 }",
        :provider => 'powershell',
      })}

      it { should contain_exec('set conflict detection attempts').with({
        :command  => "Set-DhcpServerSetting -ConflictDetectionAttempts 0",
        :unless   => "if ((Get-DhcpServerSetting).ConflictDetectionAttempts -ne 0) { exit 1 }",
        :provider => 'powershell',
      })}

      # windows_dhcp::service
      it { should contain_service('dhcpserver') }
    end

    describe "with optional parameters" do
      (0..5).to_a.each do |opt|
        context "when conflict_detection_attempts param is set to #{opt}" do
          let :params do default_params.merge({ :conflict_detection_attempts => opt }) end

          it { should contain_exec('set conflict detection attempts').with({
            :command  => "Set-DhcpServerSetting -ConflictDetectionAttempts #{opt}",
            :unless   => "if ((Get-DhcpServerSetting).ConflictDetectionAttempts -ne #{opt}) { exit 1 }",
            :provider => 'powershell',
          })}
        end
      end

      [true, false].each do |opt|
        context "when populate_security_group param is set to #{opt}" do
          let :params do default_params.merge({ :populate_security_group => opt }) end

          if opt == true
            it { should contain_exec('add CONTOSO\dhcp_admin to "DHCP Administrators"').with(add_user_to_group_hash).that_comes_before('exec[authorise server]').that_requires('exec[add DHCP security groups]') }
          else
            it { should_not contain_exec('add CONTOSO\dhcp_admin to "DHCP Administrators"').with(add_user_to_group_hash) }
          end

        end
      end
    end
  end

  context 'unsupported operating system' do
    let(:facts) {{
      :osfamily        => 'Solaris',
      :operatingsystem => 'Nexenta',
    }}

    describe 'without any parameters' do
      let(:params) do default_params end
      it { expect { should contain_windowsfeature('windows_dhcp') }.to raise_error(Puppet::Error, /not supported on/) }
    end
  end
end
