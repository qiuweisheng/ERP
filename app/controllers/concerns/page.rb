module Page
  extend ActiveSupport::Concern
  
  module ClassMethods
    attr_accessor :page_size
  end

  protected
  def page_size
    self.class.page_size
  end
  
  def offset(page)
    (to_int(page) - 1) * page_size
  end
  
  def to_int(page)
    page.to_i > 0 && page.to_i || 1
  end
  
  def prev_and_next_page(page, collection_size)
    prev_page_num = to_int(page) - 1 if to_int(page) > 1
    next_page_num = to_int(page) + 1 if to_int(page) < index_to_page(collection_size) 
    [prev_page_num, next_page_num]
  end
  
  # Start from 1
  def index_to_page(index)
    (index + page_size - 1) / page_size
  end
end