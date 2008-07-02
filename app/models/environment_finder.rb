class EnvironmentFinder
  
  def initialize env
    @environment = env
  end

  def find(asset, query = nil, options={})
    @region = Region.find_by_id(options.delete(:region)) if options.has_key?(:region)
    if @region && options[:within]
      options[:origin] = [@region.lat, @region.lng]
    else
      options.delete(:within)
    end

    product_category = options.delete(:product_category)
    product_category_ids = product_category.map_traversal(&:id) if product_category

    if query.blank?
        if product_category && asset == :products
          @environment.send(asset).find(:all, options.merge({:order => 'created_at desc, id desc', :conditions => ['product_category_id in (?)', product_category_ids]}))
        elsif product_category && asset == :enterprises
          @environment.send(asset).find(:all, options.merge(:order => 'profiles.created_at desc, profiles.id desc', :include => 'products', :conditions => ['products.product_category_id in (?)', product_category_ids]))
        else
          @environment.send(asset).find( :all, options.merge( {:order => 'created_at desc, id desc'} ) )
        end
    else
      if product_category && asset == :products
        # SECURITY no risk of SQL injection, since product_category_ids comes from trusted source
        @environment.send(asset).find_by_contents(query, {}, options.merge({:conditions => 'product_category_id in (%s)' % product_category_ids.join(',') }))
      elsif product_category && asset == :enterprises
        @environment.send(asset).find_by_contents(query + " +extra_data_for_index:#{product_category.name}", {}, options)
      else
        @environment.send(asset).find_by_contents(query, {}, options)
      end
    end
  end

  def recent(asset, limit = nil)
    find(asset, nil, :limit => limit)
  end

  def find_by_initial(asset, initial)
    @environment.send(asset).find_by_initial(initial)
  end

  def count(asset, query = '', options = {})
    if query.blank?
      # SLOW
      find(asset, query, options).size
    else
      find(asset, query, options).total_hits
    end
  end

end
