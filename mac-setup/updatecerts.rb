require 'English'
require 'pathname'

def install_certs(path, certs)
  if path.exist? then
    puts "Updating #{path}"
  else
    return
  end
  File.open(path, 'w') do |file|
    file.write certs.join("\n") << "\n"
  end
end

keychains = %w[
  /System/Library/Keychains/SystemRootCertificates.keychain
]
certs_list = `security find-certificate -a -p #{keychains.join(" ")}`
certs = certs_list.scan(
  /-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m,
)
valid_certs = certs.select do |cert|
  IO.popen("/usr/local/opt/openssl@1.1/bin/openssl x509 -inform pem -checkend 0 -noout >/dev/null", "w") do |openssl_io|
    openssl_io.write(cert)
    openssl_io.close_write
  end
  $CHILD_STATUS.success?
end
valid_certs << File.read(File.expand_path("~/Source/yesss/puppet/site/yesss/files/bits/sslca/dc-wien-05.crt"))

install_certs Pathname("/usr/local/etc/openssl/cert.pem"), valid_certs
install_certs Pathname("/usr/local/etc/openssl@1.1/cert.pem"), valid_certs
