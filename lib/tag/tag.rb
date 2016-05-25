module SizeTagging
  class Tag
    def initialize(product)
      @product = product
      @size_option = product_size_option
      ## Make a copy to compare
      @initial_product_tags = product.tags
    end

    def product_size_option
      size_opt = @product.options.select { |opt| opt.name.downcase == 'size' }
      if size_opt.any?
        "option#{size_opt.first.position}"
      end
    end

    def has_size_option?
      product_size_option
    end


    def custom_price_tag
      # 'price_' + @product..gsub('.','')
    end

    def removed_initial_tags
      # binding.pry
      @product.tags.split(',').delete_if { |x| x.include?('size_') }
    end

    def add_size_tags
      @product.tags = removed_initial_tags
      if has_size_option?      
        if has_variants?
          variants.each do |variant|
            @product.tags = [@product.tags,size_tag(variant)].join(',')
          end
        end
      end
      puts "PRODUCT ID (before): #{@product.id}"
      puts "#{initial_tags} ====> #{cleaned_tags}"
      if tags_changed?
        # puts "#{@product.title} : Updated Tags!"
        @product.tags = cleaned_tags
        @product.save!
        puts "PRODUCT ID (after): #{@product.id}"
        sleep(1.second) ## For the API
      else
        # puts "#{@product.title} : No Change in Tags!"
      end
    end

    def has_variants?
      variants.any?
    end

    def variants
      @product.variants
    end

    def cleaned_tags
      @product.tags.split(',').reject{ |c| c.empty? or c == "  " }.uniq.join(',')
    end

    def initial_tags
      @initial_product_tags
    end

    def tags_changed?
      clean_tags(initial_tags) != clean_tags(cleaned_tags)
    end

    def clean_tags(tags)
      tags.split(',').map{ |t| t.strip }.uniq.sort
    end

    def size_tag(v)
      tag = ''
      if v.inventory_quantity >= 1
        tag = "size_#{ v.send(product_size_option).parameterize}"
      end
      tag
    end

    def self.process_all_tags
      Product.all_products_array.each do |page|
        page.each do |product|
          Tag.new(product).add_size_tags
        end
      end
    end

    def self.process_recent_tags
      Product.recent_products_array.each do |page|
        page.each do |product|
          Tag.new(product).add_size_tags
        end
      end
    end
    

  end
end
