require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  test 'name must be present' do
    product = Product.new
    assert product.invalid?
  end

  test 'name must be unique' do
    product = Product.new(name: products(:one).name)
    assert product.invalid?
  end
end
