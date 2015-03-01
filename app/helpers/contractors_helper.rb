module ContractorsHelper
  def contractor_options
    Contractor.all.collect { |contractor| [contractor.name, contractor.id] }
  end
end
