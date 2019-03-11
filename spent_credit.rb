class SpentCredit < Credit
  attr_reader :type, :quantity, :period
  def initialize(type, quantity, period=nil)
    super quantity
    @type = type
    @period = period
  end
end