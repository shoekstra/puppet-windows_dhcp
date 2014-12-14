require 'spec_helper'

describe 'windows_dhcp::scope', :type => :define do
  let(:default_params) {{
    :startrange       => '192.168.10.10',
    :endrange         => '192.168.10.99',
    :scopename        => 'LAN',
    :subnetmask       => '255.255.255.0',
    :dnsdomain        => 'CONTOSO.LOCAL',
    :activatepolicies => true,
    :delay            => 0,
    :leaseduration    => '8.00:00:00',
    :maxbootpclients  => 4294967295,
    :state            => 'active',
    :type             => 'dhcp'
  }}
  let(:facts) {{
    :domain           => 'CONTOSO.LOCAL',
    :fqdn             => 'DHCPSERVER.CONTOSO.LOCAL',
    :kernelversion    => '6.2',
    :osfamily         => 'Windows',
    :operatingsystem  => 'Windows',
  }}
  let(:title) { '192.168.10.0' }

  let(:pre_condition) { 'class { "windows_dhcp": domain_user => "CONTOSO\\dhcp_admin", domain_pass => "q1w2e3", }' }
  let(:params) { default_params }

  it { should compile.with_all_deps }

  it { should contain_class('windows_dhcp') }
  it { should contain_windows_dhcp__scope(title) }

  context "when creating a scope with minimum parameters set" do
    options = "-EndRange 192.168.10.99 -StartRange 192.168.10.10 -SubnetMask 255.255.255.0 -Name LAN -Description \"\" -ActivatePolicies \$true -Delay 0 -LeaseDuration 8.00:00:00 -MaxBootpClients 4294967295 -State active -Type dhcp"

    it { should contain_exec('add 192.168.10.0').with({
      :command => "Add-DhcpServerv4Scope #{options}",
      :unless  => "if (Get-DhcpServerv4Scope 192.168.10.0) { exit 0 } else { exit 1 }",
      :provider => 'powershell',
    })}
  end

  context "when creating a scope with description set to 'Local Area Network'" do
    let(:params) { default_params.merge({ :description => 'Local Area Network' })}
    options = "-EndRange 192.168.10.99 -StartRange 192.168.10.10 -SubnetMask 255.255.255.0 -Name LAN -Description \"Local Area Network\" -ActivatePolicies \$true -Delay 0 -LeaseDuration 8.00:00:00 -MaxBootpClients 4294967295 -State active -Type dhcp"

    it { should contain_exec('add 192.168.10.0').with({
      :command => "Add-DhcpServerv4Scope #{options}",
      :unless  => "if (Get-DhcpServerv4Scope 192.168.10.0) { exit 0 } else { exit 1 }",
      :provider => 'powershell',
    })}
  end

  context "when startrange is set to '192.168.10.10'" do
    it { should contain_exec('set 192.168.10.0 start range').with({
      :command  => "Set-DhcpServerv4Scope 192.168.10.0 -StartRange 192.168.10.10",
      :unless   => "if ((Get-DhcpServerv4Scope 192.168.10.0).startrange.IPAddressToString -ne \"192.168.10.10\") { exit 1 }",
      :provider => 'powershell',
      :require  => 'Exec[add 192.168.10.0]',
    })}
  end

  context "when endrange is set to '192.168.10.99'" do
    it { should contain_exec('set 192.168.10.0 end range').with({
      :command  => "Set-DhcpServerv4Scope 192.168.10.0 -EndRange 192.168.10.99",
      :unless   => "if ((Get-DhcpServerv4Scope 192.168.10.0).endrange.IPAddressToString -ne \"192.168.10.99\") { exit 1 }",
      :provider => 'powershell',
      :require  => 'Exec[add 192.168.10.0]',
    })}
  end

  context "when name is set to 'Local Area Network'" do
    let(:params) { default_params.merge({ :name => 'Local Area Network' })}
    it { should contain_exec('set 192.168.10.0 name').with({
      :command  => "Set-DhcpServerv4Scope 192.168.10.0 -Name \"Local Area Network\"",
      :unless   => "if ((Get-DhcpServerv4Scope 192.168.10.0).Name -ne \"Local Area Network\") { exit 1 }",
      :provider => 'powershell',
      :require  => 'Exec[add 192.168.10.0]',
    })}
  end

  context "when dnsdomain is set to 'CONTOSO.LOCAL'" do
    it { should contain_exec('set 192.168.10.0 dns domain').with({
      :command  => "Set-DhcpServerv4OptionValue 192.168.10.0 -DnsDomain CONTOSO.LOCAL",
      :unless   => "if ((Get-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -OptionId 15).value -ne \"CONTOSO.LOCAL\") { exit 1 }",
      :provider => 'powershell',
      :require  => 'Exec[add 192.168.10.0]',
    })}
  end

  context "when dnsserver is set to '192.168.10.100'" do
    let(:params) { default_params.merge({ :dnsserver => '192.168.10.100' })}

    it { should contain_exec('set 192.168.10.0 dns server').with({
      :command  => "Set-DhcpServerv4OptionValue 192.168.10.0 -DnsServer 192.168.10.100",
      :unless   => "if ((Compare-Object (Get-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -OptionId 6).value 192.168.10.100).count -gt 0) { exit 1 }",
      :provider => 'powershell',
      :require  => 'Exec[add 192.168.10.0]'
    })}
  end

  context "when dnsserver is set to '[192.168.10.100, 192.168.10.200]'" do
    let(:params) { default_params.merge({ :dnsserver => ['192.168.10.100', '192.168.10.200'] })}

    it { should contain_exec('set 192.168.10.0 dns server').with({
      :command  => "Set-DhcpServerv4OptionValue 192.168.10.0 -DnsServer @('192.168.10.100','192.168.10.200')",
      :unless   => "if ((Compare-Object (Get-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -OptionId 6).value @('192.168.10.100','192.168.10.200')).count -gt 0) { exit 1 }",
      :provider => 'powershell',
      :require  => 'Exec[add 192.168.10.0]'
    })}
  end

  context "when router is set to '192.168.10.1'" do
    let(:params) { default_params.merge({ :router => '192.168.10.1' })}

    it { should contain_exec('set 192.168.10.0 router').with({
      :command  => "Set-DhcpServerv4OptionValue 192.168.10.0 -Router 192.168.10.1",
      :unless   => "if ((Get-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -OptionId 3).value -ne \"192.168.10.1\") { exit 1 }",
      :provider => 'powershell',
      :require  => 'Exec[add 192.168.10.0]',
    })}
  end

  [true, false].each do |bool|
    describe "when activatepolicies is set to #{bool}" do
      let(:params) { default_params.merge({ :activatepolicies => bool })}

      it { should contain_exec('set 192.168.10.0 activatepolicies').with({
        :command  => "Set-DhcpServerv4Scope 192.168.10.0 -ActivatePolicies \$#{bool}",
        :unless   => "if ((Get-DhcpServerv4Scope 192.168.10.0).ActivatePolicies -ne \$#{bool}) { exit 1 }",
        :provider => 'powershell',
        :require  => 'Exec[add 192.168.10.0]',
      })}
    end
  end

  [0, 5000].each do |opt|
    describe "when delay is set to #{opt}" do
      let(:params) { default_params.merge({ :delay => opt })}

      it { should contain_exec('set 192.168.10.0 delay').with({
        :command  => "Set-DhcpServerv4Scope 192.168.10.0 -Delay #{opt}",
        :unless   => "if ((Get-DhcpServerv4Scope 192.168.10.0).delay -ne \"#{opt}\") { exit 1 }",
        :provider => 'powershell',
        :require  => 'Exec[add 192.168.10.0]',
      })}
    end
  end

  context "when description is set to 'Local Area Network'" do
    let(:params) { default_params.merge({ :description => 'Local Area Network' })}

    it { should contain_exec('set 192.168.10.0 description').with({
      :command  => "Set-DhcpServerv4Scope 192.168.10.0 -description \"Local Area Network\"",
      :unless   => "if ((Get-DhcpServerv4Scope 192.168.10.0).description -ne \"Local Area Network\") { exit 1 }",
      :provider => 'powershell',
      :require  => 'Exec[add 192.168.10.0]',
    })}
  end

  describe "when leaseduration is set to '1.00:00:00" do
    let(:params) { default_params.merge({ :leaseduration => '1.00:00:00' })}

    it { should contain_exec('set 192.168.10.0 leaseduration').with({
      :command  => "Set-DhcpServerv4Scope 192.168.10.0 -LeaseDuration 1.00:00:00",
      :unless   => "if ((Get-DhcpServerv4Scope 192.168.10.0).leaseduration -ne \"1.00:00:00\") { exit 1 }",
      :provider => 'powershell',
      :require  => 'Exec[add 192.168.10.0]',
    })}
  end

  describe "when maxbootpclients is set to '100000'" do
    let(:params) { default_params.merge({ :maxbootpclients => 100000 })}

    it { should contain_exec('set 192.168.10.0 maxbootpclients').with({
      :command  => "Set-DhcpServerv4Scope 192.168.10.0 -maxbootpclients 100000",
      :unless   => "if ((Get-DhcpServerv4Scope 192.168.10.0).maxbootpclients -ne \"100000\") { exit 1 }",
      :provider => 'powershell',
      :require  => 'Exec[add 192.168.10.0]',
    })}
  end

  ['active', 'inactive'].each do |opt|
    describe "when state is set to #{opt}" do
      let(:params) { default_params.merge({ :state => opt })}

      it { should contain_exec('set 192.168.10.0 state').with({
        :command  => "Set-DhcpServerv4Scope 192.168.10.0 -state #{opt}",
        :unless   => "if ((Get-DhcpServerv4Scope 192.168.10.0).state -ne \"#{opt}\") { exit 1 }",
        :provider => 'powershell',
        :require  => 'Exec[add 192.168.10.0]',
      })}
    end
  end

  ['bootp', 'dhcp', 'both'].each do |opt|
    describe "when type is set to #{opt}" do
      let(:params) { default_params.merge({ :type => opt })}

      it { should contain_exec('set 192.168.10.0 type').with({
        :command  => "Set-DhcpServerv4Scope 192.168.10.0 -Type #{opt}",
        :unless   => "if ((Get-DhcpServerv4Scope 192.168.10.0).type -ne \"#{opt}\") { exit 1 }",
        :provider => 'powershell',
        :require  => 'Exec[add 192.168.10.0]',
      })}
    end
  end
end
