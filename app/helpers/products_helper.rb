module ProductsHelper
  def product_options_all
    product_map = []
    product_map << ['全部', -1]
    product_map += Product.all.collect { |product| [product.name, product.id] }
  end
end
