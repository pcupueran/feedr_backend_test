class SubsidisedCredit < Credit
  attr_reader :type, :period

  def initialize(quantity, type, period)
    super quantity
    @type = type
    @period = period
  end
end