require 'spec_helper_acceptance'

# It is sometimes faster to host confluence / java files on a local webserver.
# Set environment variable download_url to use local webserver
# export download_url = 'http://10.0.0.XXX/'
download_url = ENV['download_url'] if ENV['download_url']
download_url = if ENV['download_url']
                 ENV['download_url']
               else
                 'undef'
               end

describe 'confluence', unless: UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  it 'upgrades with defaults' do
    pp = <<-EOS
      $jh = $osfamily ? {
        default   => '/opt/java',
      }
      if versioncmp($::puppetversion,'3.6.1') >= 0 {
        $allow_virtual_packages = hiera('allow_virtual_packages',false)
        Package {
          allow_virtual => $allow_virtual_packages,
        }
      }
      class { 'confluence':
        version             => '5.7',
        download_url        => #{download_url},
        javahome            => $jh,
      }
    EOS
    apply_manifest(pp, catch_failures: true)
    shell 'wget -q --tries=240 --retry-connrefused --read-timeout=10 localhost:8090', acceptable_exit_codes: [0]
    sleep 60
    shell 'wget -q --tries=240 --retry-connrefused --read-timeout=10 localhost:8090', acceptable_exit_codes: [0]
    sleep 30
    apply_manifest(pp, catch_changes: true)
  end

  describe process('java') do
    it { is_expected.to be_running }
  end

  describe port(8090) do
    it { is_expected.to be_listening }
  end

  describe service('confluence') do
    it { is_expected.to be_enabled }
  end

  describe user('confluence') do
    it { is_expected.to exist }
  end

  describe user('confluence') do
    it { is_expected.to belong_to_group 'confluence' }
  end

  describe user('confluence') do
    it { is_expected.to have_login_shell '/bin/true' }
  end

  describe command('wget -q --tries=240 --retry-connrefused --read-timeout=10 -O- localhost:8090') do
    its(:stdout) { is_expected.to match %r{http://www.atlassian.com/} }
  end
end
