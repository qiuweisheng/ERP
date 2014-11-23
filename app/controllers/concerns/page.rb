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
    (page_num(page) - 1) * page_size
  end
  
  def page_num(page)
    (page || 1).to_i
  end
  
  def prev_and_next_page(page, collection_size)
    page_total = (collection_size + page_size - 1) / page_size
    prev_page_num = page_num(page) - 1 if page_num(page) > 1
    next_page_num = page_num(page) + 1 if page_num(page) < page_total 
    [prev_page_num, next_page_num]
  end
end