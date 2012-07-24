
require "openssl"
require "base64"

module Bixby
class Agent

module Crypto

  # create crypto keypair and save in config folder
  def create_keypair
    init_config_dir()
    pair = OpenSSL::PKey::RSA.generate(2048)
    File.open(private_key_file, 'w') { |out| out.write(pair.to_s) }
  end

  def private_key_file
    File.join(self.config_dir, "id_rsa")
  end

  def keypair
    @keypair ||= OpenSSL::PKey::RSA.new(File.read(private_key_file))
  end

  def public_key
    @public_key ||= keypair.public_key
  end

  def private_key
    keypair
  end

  def server_key_file
    File.join(self.config_dir, "server.pub")
  end

  def have_server_key?
    File.exists? server_key_file
  end

  def server_key
    @server_key ||= OpenSSL::PKey::RSA.new(File.read(server_key_file))
  end

  def crypto_enabled?
    b = ENV["BIXBY_NOCRYPTO"]
    !(b and %w{1 true yes}.include? b)
  end

  # Encrypt data using the server's public key
  #
  # @param [String] data    data to encrypt
  #
  # @return [String] Base64 result
  def encrypt_for_server(data)
    c = new_cipher()
    c.encrypt
    key = c.random_key
    iv = c.random_iv
    encrypted = c.update(data) + c.final

    out = []
    out << Base64.encode64(server_key.public_encrypt(key)).gsub(/\n/, "\\n")
    out << Base64.encode64(keypair.private_encrypt(iv)).gsub(/\n/, "\\n")
    out << Base64.encode64(encrypted)

    return out.join("\n")
  end

  # Decrypt data that was encrypted with our public key
  #
  # @param [String] data    Base64 encoded data
  #
  # @return [String] unencrypted data
  def decrypt_from_server(data)
    data = StringIO.new(data, 'rb')
    key = keypair.private_decrypt(Base64.decode64(data.readline.gsub(/\\n/, "\n")))
    iv  = server_key.public_decrypt(Base64.decode64(data.readline.gsub(/\\n/, "\n")))

    c = new_cipher()
    c.decrypt
    c.key = key
    c.iv = iv

    data = Base64.decode64(data.read)
    ret = c.update(data) + c.final
  end

  def new_cipher
    OpenSSL::Cipher.new("AES-256-CBC")
  end

end # Crypto

end # Agent
end # Bixby
