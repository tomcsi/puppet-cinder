require 'spec_helper'

describe 'cinder::api' do

  let :req_params do
    {:keystone_password => 'foo'}
  end
  let :facts do
    {:osfamily       => 'Debian',
     :processorcount => 8 }
  end

  describe 'with only required params' do
    let :params do
      req_params
    end

    it { should contain_service('cinder-api').with(
      'hasstatus' => true,
      'ensure' => 'running'
    )}

    it 'should configure cinder api correctly' do
      should contain_cinder_config('DEFAULT/auth_strategy').with(
       :value => 'keystone'
      )
      should contain_cinder_config('DEFAULT/osapi_volume_listen').with(
       :value => '0.0.0.0'
      )
      should contain_cinder_config('DEFAULT/osapi_volume_workers').with(
       :value => '8'
      )
      should contain_cinder_config('DEFAULT/default_volume_type').with(
       :ensure => 'absent'
      )
      should contain_cinder_api_paste_ini('filter:authtoken/service_protocol').with(
        :value => 'http'
      )
      should contain_cinder_api_paste_ini('filter:authtoken/service_host').with(
        :value => 'localhost'
      )
      should contain_cinder_api_paste_ini('filter:authtoken/service_port').with(
        :value => '5000'
      )
      should contain_cinder_api_paste_ini('filter:authtoken/identity_uri').with(
        :value => 'http://localhost:35357'
      )
      should contain_cinder_api_paste_ini('filter:authtoken/auth_protocol').with(
        :ensure => 'absent'
      )
      should contain_cinder_api_paste_ini('filter:authtoken/auth_host').with(
        :ensure => 'absent'
      )
      should contain_cinder_api_paste_ini('filter:authtoken/auth_port').with(
        :ensure => 'absent'
      )
      should contain_cinder_api_paste_ini('filter:authtoken/auth_admin_prefix').with(
        :ensure => 'absent'
      )
      should contain_cinder_api_paste_ini('filter:authtoken/admin_tenant_name').with(
        :value => 'services'
      )
      should contain_cinder_api_paste_ini('filter:authtoken/admin_user').with(
        :value => 'cinder'
      )
      should contain_cinder_api_paste_ini('filter:authtoken/admin_password').with(
        :value  => 'foo',
        :secret => true
      )

      should contain_cinder_api_paste_ini('filter:authtoken/auth_uri').with(
        :value => 'http://localhost:5000/'
      )

      should_not contain_cinder_config('DEFAULT/os_region_name')

    end
  end

  describe 'with a custom region for nova' do
    let :params do
      req_params.merge({'os_region_name' => 'MyRegion'})
    end
    it 'should configure the region for nova' do
      should contain_cinder_config('DEFAULT/os_region_name').with(
        :value => 'MyRegion'
      )
    end
  end

  describe 'with a default volume type' do
    let :params do
      req_params.merge({'default_volume_type' => 'foo'})
    end
    it 'should configure the default volume type for cinder' do
      should contain_cinder_config('DEFAULT/default_volume_type').with(
        :value => 'foo'
      )
    end
  end

  describe 'with custom auth_uri' do
    let :params do
      req_params.merge({'keystone_auth_uri' => 'http://foo.bar:8080/v2.0/'})
    end
    it 'should configure cinder auth_uri correctly' do
      should contain_cinder_api_paste_ini('filter:authtoken/auth_uri').with(
        :value => 'http://foo.bar:8080/v2.0/'
      )
    end
  end

  describe 'with only required params' do
    let :params do
      req_params.merge({'bind_host' => '192.168.1.3'})
    end
    it 'should configure cinder api correctly' do
      should contain_cinder_config('DEFAULT/osapi_volume_listen').with(
       :value => '192.168.1.3'
      )
    end
  end

  [ '/keystone', '/keystone/admin', '' ].each do |keystone_auth_admin_prefix|
    describe "with keystone_auth_admin_prefix containing incorrect value #{keystone_auth_admin_prefix}" do
      let :params do
        {
          :keystone_auth_admin_prefix => keystone_auth_admin_prefix,
          :keystone_password    => 'dummy'
        }
      end

      it { should contain_cinder_api_paste_ini('filter:authtoken/identity_uri').with(
        :value => "http://localhost:35357#{keystone_auth_admin_prefix}"
      )}
    end
  end

  [
    '/keystone/',
    'keystone/',
    'keystone',
    '/keystone/admin/',
    'keystone/admin/',
    'keystone/admin'
  ].each do |keystone_auth_admin_prefix|
    describe "with keystone_auth_admin_prefix containing incorrect value #{keystone_auth_admin_prefix}" do
      let :params do
        {
          :keystone_auth_admin_prefix => keystone_auth_admin_prefix,
          :keystone_password    => 'dummy'
        }
      end

      it { expect { should contain_cinder_api_paste_ini('filter:authtoken/identity_uri') }.to \
        raise_error(Puppet::Error, /validate_re\(\): "#{keystone_auth_admin_prefix}" does not match/) }
    end
  end

  describe 'with enabled false' do
    let :params do
      req_params.merge({'enabled' => false})
    end
    it 'should stop the service' do
      should contain_service('cinder-api').with_ensure('stopped')
    end
    it 'should contain db_sync exec' do
      should_not contain_exec('cinder-manage db_sync')
    end
  end

  describe 'with manage_service false' do
    let :params do
      req_params.merge({'manage_service' => false})
    end
    it 'should not change the state of the service' do
      should contain_service('cinder-api').without_ensure
    end
  end

  describe 'with ratelimits' do
    let :params do
      req_params.merge({ :ratelimits => '(GET, "*", .*, 100, MINUTE);(POST, "*", .*, 200, MINUTE)' })
    end

    it { should contain_cinder_api_paste_ini('filter:ratelimit/limits').with(
      :value => '(GET, "*", .*, 100, MINUTE);(POST, "*", .*, 200, MINUTE)'
    )}
  end

  describe 'while validating the service with default command' do
    let :params do
      req_params.merge({
        :validate => true,
      })
    end
    it { should contain_exec('execute cinder-api validation').with(
      :path        => '/usr/bin:/bin:/usr/sbin:/sbin',
      :provider    => 'shell',
      :tries       => '10',
      :try_sleep   => '2',
      :command     => 'cinder --os-auth-url http://localhost:5000/ --os-tenant-name services --os-username cinder --os-password foo list',
    )}

    it { should contain_anchor('create cinder-api anchor').with(
      :require => 'Exec[execute cinder-api validation]',
    )}
  end

  describe 'while validating the service with custom command' do
    let :params do
      req_params.merge({
        :validate            => true,
        :validation_options  => { 'cinder-api' => { 'command' => 'my-script' } }
      })
    end
    it { should contain_exec('execute cinder-api validation').with(
      :path        => '/usr/bin:/bin:/usr/sbin:/sbin',
      :provider    => 'shell',
      :tries       => '10',
      :try_sleep   => '2',
      :command     => 'my-script',
    )}

    it { should contain_anchor('create cinder-api anchor').with(
      :require => 'Exec[execute cinder-api validation]',
    )}
  end

end
