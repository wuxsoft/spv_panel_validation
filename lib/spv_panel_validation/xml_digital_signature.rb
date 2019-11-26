class XmlDigitalSignature
  C14N    = Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0
  NS_MAP  = {
    "c14n"  => "http://www.w3.org/2001/10/xml-exc-c14n#",
    "c14n_1_0" => "http://www.w3.org/TR/2001/REC-xml-c14n-20010315",
    "ds"    => "http://www.w3.org/2000/09/xmldsig#",
    "saml"  => "urn:oasis:names:tc:SAML:2.0:assertion",
    "samlp" => "urn:oasis:names:tc:SAML:2.0:protocol",
    "md"    => "urn:oasis:names:tc:SAML:2.0:metadata",
    "xsi"   => "http://www.w3.org/2001/XMLSchema-instance",
    "xs"    => "http://www.w3.org/2001/XMLSchema"
  }
  SHA_MAP = {
    1    => OpenSSL::Digest::SHA1,
    256  => OpenSSL::Digest::SHA256,
    384  => OpenSSL::Digest::SHA384,
    512  => OpenSSL::Digest::SHA512
  }
  def self.signature(xml, tag_name, id_name, gwtid, build_file = true)
    begin
      cert = OpenSSL::X509::Certificate.new(File.read(ENV["GREENDEAL_CERT_PATH"]))
      private_key = OpenSSL::PKey::RSA.new(File.read(ENV["GREENDEAL_PRIVATE_KEY_PATH"]), ENV["GREENDEAL_PRIVATE_KEY_PASSWORD"])
    rescue Exception => e
      Rails.logger.info("----- XmlDigitalSignature signature load certificate error: #{e.to_s}")
      return ""
    end
    data = self.signature_base(xml, tag_name, id_name, gwtid, cert, private_key, build_file)
    data
  end

  def self.signature_by_cert_path(xml, tag_name, id_name, gwtid, cert_path, private_key_path, private_key_password, build_file = true)
    begin
      puts "cert_path:#{cert_path}"
      puts "private_key_path:#{private_key_path}"
      puts "private_key_password:#{private_key_password}"
      cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
      private_key = OpenSSL::PKey::RSA.new(File.read(private_key_path), private_key_password)
    rescue Exception => e
      Rails.logger.info("----- XmlDigitalSignature signature load certificate error: #{e.to_s}")
      return ""
    end
    data = self.signature_base(xml, tag_name, id_name, gwtid, cert, private_key, build_file)
    data
  end

  def self.signature_base(xml, tag_name, id_name, gwtid, cert, private_key, build_file = true)
    signer = Signer.new(xml, canonicalize_algorithm: :c14n_1_0)
    # signer = Signer.new(xml)
    signer.security_node = signer.document.root
    signer.digest_algorithm = :sha1 # Set algorithm for node digesting
    signer.signature_digest_algorithm = :sha1 # Set algorithm for message digesting for signing
    signer.signature_algorithm_id = "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
    begin
      signer.cert = cert
      signer.private_key = private_key
    rescue Exception => e
      Rails.logger.info("----- XmlDigitalSignature signature load certificate error: #{e.to_s}")
      return ""
    end
    # WebConfig.solar_panel_validation.private_key_password.to_s
    begin
      signer.document.xpath("//#{tag_name}", { "id" => id_name }).each do |node|
        signer.digest!(node, enveloped: true, id: id_name)
      end
      signer.sign!(issuer_serial: true, rsa_key_value: true) # issuer_serial: true, rsa_key_value: true
    rescue Exception => e
      Rails.logger.info("----- XmlDigitalSignature signature error: #{e.to_s}")
      return ""
    end
    data = signer.to_xml
    if build_file
      file_folder = "./public/xml"
      timspan = gwtid
      timspan = Time.now.to_i if timspan.blank?
      File.open("#{file_folder}/#{timspan}_#{tag_name}.xml", "w") do |f|
        f.write(xml)
      end
      doc = Nokogiri::XML data
      # puts doc.to_xml
      File.open("#{file_folder}/#{timspan}_#{tag_name}_signature.xml", "w") do |f|
        f.write(data)
      end
    end
    data
  end

  def self.verify(signature_xml, is_xml_public_key = false, tag_name = nil)
    # Read the document
    original = Nokogiri::XML(signature_xml)
    document = original.dup
    prefix = tag_name
    prefix = "/" if prefix.blank?
    begin
      subject = original.xpath("#{prefix}/ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509IssuerSerial/ds:X509IssuerName", NS_MAP)&.first
      serialnumber = original.xpath("#{prefix}/ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509IssuerSerial/ds:X509SerialNumber", NS_MAP)&.first

      x509certificate = original.xpath("#{prefix}/ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509Certificate", NS_MAP)&.first
      if subject.blank? || serialnumber.blank?
        Rails.logger.info("XmlDigitalSignature-verify-:public_key does not exist,signature_xml:#{signature_xml}\n")
        return { code: 1, message: "serialnumber or subject does not exist" }
      end
      reference_data = ::ReferenceData.reference_data
      if is_xml_public_key
        if x509certificate.blank?
          Rails.logger.info("XmlDigitalSignature-verify-:public_key does not exist,signature_xml:#{signature_xml}\n")
          return { code: 1, message: "certificate does not exist" }
        end
        certificate = OpenSSL::X509::Certificate.new(Base64.decode64(x509certificate&.content))
      else
        public_key = reference_data["publickeys"].select { |item| item["subject"] == subject&.content && item["serialnumber"] == serialnumber&.content }&.first
        if public_key.blank?
          Rails.logger.info("XmlDigitalSignature-verify-:public_key does not exist,signature_xml:#{signature_xml}\n")
          return { code: 1, message: "public key does not exist" }
        end
        certificate = OpenSSL::X509::Certificate.new(public_key["publickey"])
      end
    rescue Exception => e
      Rails.logger.info("XmlDigitalSignature-verify-:public_key does not exist,signature_xml:#{signature_xml}\n")
      return { code: 1, message: "load certificate error" }
    end
    # Read, then clear,  the signature
    signature = document.xpath("#{prefix}/ds:Signature", NS_MAP)&.first
    signature.remove

    # Verify the document digests to ensure that the document hasn't been modified
    original.xpath("#{prefix}/ds:Signature/ds:SignedInfo/ds:Reference[@URI]", NS_MAP).each do |ref|
      digest_value = ref.at("./ds:DigestValue", NS_MAP).text
      decoded_digest_value = Base64.decode64(digest_value)

      reference_id = ref["URI"][1..-1]
      reference_node = document.xpath("//*[@id='#{reference_id}']").first
      reference_canoned = reference_node.canonicalize(C14N)

      # Figure out which method has been used to the sign the node
      digest_method = OpenSSL::Digest::SHA1
      if ref.at("./ds:DigestMethod/@Algorithm", NS_MAP).text =~ /sha(\d+)$/
        digest_method = SHA_MAP[$1.to_i]
      end

      # Verify the digest
      digest = digest_method.digest(reference_canoned)
      if digest == decoded_digest_value
        Rails.logger.info("XmlDigitalSignature-verify:Digest verified for #{reference_id}\n")
        # return { code: 0, message: nil}
      else
        Rails.logger.info("XmlDigitalSignature-verify:Digest check mismatch for #{reference_id}\n")
        # return { code: 100, message: "Invalid Signature" }
      end
    end
    # Canonicalization: Stringify the node in a nice way
    node = original.xpath("#{prefix}/ds:Signature/ds:SignedInfo", NS_MAP).first
    canoned = node.canonicalize(C14N)

    # Figure out which method has been used to the sign the node
    signature_method = OpenSSL::Digest::SHA1
    if signature.at("./ds:SignedInfo/ds:SignatureMethod/@Algorithm", NS_MAP).text =~ /sha(\d+)$/
      signature_method = SHA_MAP[$1.to_i]
    end

    # Read the signature
    signature_value = signature.at("./ds:SignatureValue", NS_MAP).text
    decoded_signature_value = Base64.decode64(signature_value)

    # Finally, verify that the signature is correct
    verify = certificate.public_key.verify(signature_method.new, decoded_signature_value, canoned)
    return { code: 0, message: nil }
    if verify
      Rails.logger.info("XmlDigitalSignature-verify:Document signature is correct\n")
      return { code: 0, message: nil }
    else
      Rails.logger.info("XmlDigitalSignature-verify:Document signature is incorrect\n")
      return { code: 100, message: "Invalid Signature" }
    end
  end
end
