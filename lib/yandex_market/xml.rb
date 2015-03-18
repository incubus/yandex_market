require "builder"


module YandexMarket
  
  
  # Builds YandexMarket XML file based on configuration.
  #
  # @author Denis Udovenko
  # @version 1.0.3
  class Xml
    
    
    # Builds XML file and saves it to Rails public directory.
    def self.build
      @output = ""
      @builder = Builder::XmlMarkup.new(target: @output)
      
      build_header
      
      @builder.yml_catalog date: Time.now.strftime("%Y-%m-%d %H:%M") do
        @builder.shop do
          shop_details
          currencies
          categories
          local_delivery_cost
          offers
        end
      end
      
      save
    end
    
    
    private
    
      
      # Builds XML header.
      def self.build_header
        @builder.instruct!    
        @builder.declare! :DOCTYPE, :yml_catalog, :SYSTEM, "shops.dtd"
      end
    
      
      # Builds shop details information.
      def self.shop_details
        shop_details_keys = [:name, :company, :url, :phone, :email]
        shop_details = YandexMarket::configuration.shop.slice *shop_details_keys
        
        shop_details.each do |key, value|
          @builder.tag! key, value
        end
      end
      
      
      # Builds currencies list.
      def self.currencies
        @builder.currencies do
          YandexMarket::configuration.shop[:currencies].each do |currency|
            @builder.currency id: currency[:id], rate: currency[:rate], plus: currency[:plus]
          end
        end
      end
      
      
      # Builds categories list.
      def self.categories
        
        # Accept categories as an array or as a proc result:
        categories = YandexMarket::configuration.shop[:categories]
        categories = categories.call if categories.class == Proc
        
        @builder.categories do
          
          categories.each do |category|
            attributes = category.slice :id, :parentId
            @builder.category category[:name], attributes
          end
        end
      end
      
      
      # Adds local delivery cost tag.
      def self.local_delivery_cost
        shop = YandexMarket::configuration.shop
        @builder.local_delivery_cost shop[:local_delivery_cost] if shop[:local_delivery_cost]
      end
      
      
      # Builds offers list.
      def self.offers
        
        # Accept offers as an array or as a proc result:
        offers = YandexMarket::configuration.shop[:offers]
        offers = offers.call if offers.class == Proc
               
        @builder.offers do
          
          offers.each do |offer|
            attribute_keys = [:id, :group_id, :type, :available];
            attributes = offer.slice *attribute_keys
            nodes = offer.except *attribute_keys
            
            @builder.offer attributes do
              nodes.each do |key, values|
                values = [values] unless values.is_a?(Array)
                values.each do |value|
                  prepared_value, prepared_attributes = value.is_a?(Hash) ?
                    [value[:value], value.except(:value)] : [value, {}]
                  @builder.tag! key, prepared_value,
                    prepared_attributes.merge(key == :categoryId ? { type: "Own" } : prepared_attributes)
                end
              end
            end
          end
        end
      end
      
      
      # Saves builder output XML data to file according to configuration.
      def self.save
        file = File.new("public/#{YandexMarket::configuration.file_name}", "wb")
        file.write(@output)
        file.close
      end
  end
end