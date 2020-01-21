
class ReferenceData
  def self.responsible_supplier(manufacturer)
    reference_data
    manufacturer_item = @reference_data["manufacturers"].select { |item| item["name"] == manufacturer}&.first if @reference_data.present?
    if manufacturer_item.present?
      manufacturer_item["suppliers"]&.first["name"]
    else
      ""
    end
  end

  def self.responsible_supplier_by_name(manufacturer, responsible_supplier_name)
    reference_data
    manufacturer_item = @reference_data["manufacturers"].select { |item| item["name"] == manufacturer}&.first if @reference_data.present?
    if manufacturer_item.present?
      supplier = manufacturer_item["suppliers"].select { |item| item["name"]&.downcase == responsible_supplier_name.downcase }&.first
      if supplier.present?
        supplier["name"]
      else
        ""
      end
    else
      ""
    end
  end
  
  def self.responsible_suppliers(manufacturer)
    reference_data
    manufacturer_item = @reference_data["manufacturers"].select { |item| item["name"] == manufacturer}&.first if @reference_data.present?
    if manufacturer_item.present?
      manufacturer_item["suppliers"]
    else
      []
    end
  end

  def self.reference_data
    begin
      @reference_data = JSON.parse(File.read(ENV["REFERENCE_DATA_PATH"])) if @reference_data.blank?
      @reference_data
    rescue Exception => e
      @reference_data = nil
      Raven.capture_exception(e)
    end
  end

  def self.api_url(manufacturer, type)
    reference_data
    manufacturer_item = @reference_data["manufacturers"].select { |item| item["name"] == manufacturer}&.first if @reference_data.present?
    if manufacturer_item.present?
      endpointid = manufacturer_item["suppliers"]&.first["endpointid"]
      endpoint_item = @reference_data["endpoints"].select { |item| item["id"] == endpointid}&.first
      if endpoint_item.present?
        endpoint_item[type]
      else
        ""
      end
    else
      ""
    end
  end

  def self.api_url_by_name(manufacturer, type, responsible_supplier_name)
    reference_data
    manufacturer_item = @reference_data["manufacturers"].select { |item| item["name"] == manufacturer}&.first if @reference_data.present?
    if manufacturer_item.present?
      endpointid = manufacturer_item["suppliers"].select { |item| item["name"]&.downcase == responsible_supplier_name.downcase }&.first["endpointid"]
      endpoint_item = @reference_data["endpoints"].select { |item| item["id"] == endpointid}&.first
      if endpoint_item.present?
        endpoint_item[type]
      else
        ""
      end
    else
      ""
    end
  end

  def self.extend_manufacturer(manufacturer)
    reference_data
    manufacturer_item = @reference_data["manufacturers"].select { |item| item["name"] == manufacturer }&.first if @reference_data.present?
    manufacturer_item.present?
  end

end