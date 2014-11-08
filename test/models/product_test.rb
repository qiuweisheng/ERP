require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  setup do
    @attrs = { name: '903线' }
  end

  test 'serial_number should be generated automatically on creation' do
    product = Product.new @attrs
    product.save
    assert_equal products(:two).serial_number + 1, product.serial_number

    Product.delete_all
    (Product::MIN_ID..Product::MAX_ID).each do
      product = Product.new @attrs
      product.save
    end
    product = Product.first
    old_id = product.serial_number
    product.destroy
    product = Product.new @attrs
    product.save
    assert_equal old_id, product.serial_number
  end

  test 'serial_number should not exceed maximum id' do
    Product.delete_all
    (Product::MIN_ID..Product::MAX_ID).each do
      product = Product.new @attrs
      product.save
    end
    product = Product.new @attrs
    assert product.invalid?
    assert_includes product.errors[:serial_number], "帐户达到最大值:#{Product::MAX_ID}"
  end

  test 'serial_number should not change on update' do
    product = products(:one)
    old_id = product.serial_number
    product.serial_number += 1
    product.save
    assert_equal old_id, product.serial_number
  end

  test 'name should be present' do
    product = Product.new
    assert product.invalid?
  end
end
