require_relative './credit.rb'
require_relative './subsidised_credit.rb'
require_relative './spent_credit.rb'
require_relative './user.rb'

class AccountingSystem
  attr_reader :credits, :subsidised_credits, :spent_credits

  def initialize
    @credits = {}
    @subsidised_credits = {}
    @spent_credits = Hash.new([])
  end

  def own_credits(user_id)
    @credits[user_id].quantity
  end

  def add_own_credits(quantity, user_id)
    if @credits[user_id]
      @credits[user_id].quantity += quantity
    else
      @credits[user_id] = Credit.new(quantity)
    end
  end

  def calculate_credit_day_allowance(user_id, period=nil)
    subsidised_credit = find_subsidised_credit(user_id, 'day', period || Time.now.strftime('%a').downcase)
    subsidised_credit && subsidised_credit.quantity - spent_subsidised_credits(user_id, 'day', period) || 0
  end

  def calculate_credit_week_allowance(user_id)
    find_subsidised_credit(user_id, 'week').quantity
  end
  def calculate_credit_month_allowance(user_id)
    find_subsidised_credit(user_id, 'month').quantity
  end

  def set_subsidised_credits(quantity, user_id, type, period=nil)
    subsidised_credit = find_subsidised_credit(user_id, type, period)
    if subsidised_credit
      subsidised_credit.quantity = quantity
    else
      @subsidised_credits[user_id] = (@subsidised_credits[user_id] || []) << SubsidisedCredit.new(quantity, type, period)
    end
  end

  def total_credits(user_id, period)
    return own_credits(user_id) + calculate_credit_day_allowance(user_id) unless period
    own_credits(user_id) + calculate_allowance(user_id, period)
  end

  def purchase_food(user_id, price_in_credits)
    day_allowance = calculate_credit_day_allowance(user_id)
    remaining_to_pay = day_allowance - price_in_credits
    subsidised_credits_spent = remaining_to_pay >= 0 ? price_in_credits : day_allowance

    final_payment = remaining_to_pay >= 0 ? 0 : own_credits(user_id) - remaining_to_pay.abs
    own_credits_spent = remaining_to_pay >= 0 ? 0 : remaining_to_pay.abs
    raise "You can't purchase this item. Insufficient funds" unless final_payment >= 0 
    @spent_credits[user_id] << SpentCredit.new('standard', own_credits_spent) if own_credits_spent > 0
    @spent_credits[user_id] << SpentCredit.new('day', subsidised_credits_spent, Time.now.strftime('%a').downcase) if subsidised_credits_spent > 0
  end

  def spent_subsidised_credits(user_id, type='day', period=nil)
    period ||= Time.now.strftime('%a').downcase
    @spent_credits[user_id].select { |c| c.type == type && c.period == period }.inject(0) { |sum, c| sum + c.quantity }
  end

  private
  def find_subsidised_credit(user_id, type, period=nil)
    @subsidised_credits[user_id] && @subsidised_credits[user_id].find { |sc| sc.type == type && sc.period == period }
  end 
end


accounting_system = AccountingSystem.new 
user = User.new(1, 'pcupueran@gmail.com')
accounting_system.add_own_credits(10, user.id)
accounting_system.set_subsidised_credits(3, user.id, 'day', 'mon')
accounting_system.set_subsidised_credits(4, user.id, 'day', 'tue')
accounting_system.set_subsidised_credits(4, user.id, 'week')
accounting_system.set_subsidised_credits(8, user.id, 'month')
puts "own credits: #{accounting_system.own_credits(user.id)}"
puts "mon allowance: #{accounting_system.calculate_credit_day_allowance(user.id, 'mon')}"
puts "tue allowance: #{accounting_system.calculate_credit_day_allowance(user.id, 'tue')}"

puts "weekly allowance: #{accounting_system.calculate_credit_week_allowance(user.id)}"
puts "monthly allowance: #{accounting_system.calculate_credit_month_allowance(user.id)}"

puts "mon allowance before purchase: #{accounting_system.spent_subsidised_credits(user.id)}"
puts "mon purchase: #{accounting_system.purchase_food(user.id, 2)}"
puts "mon subsidised credits after purchase: #{accounting_system.spent_subsidised_credits(user.id, 'mon')}"
puts accounting_system.credits
puts accounting_system.subsidised_credits

accounting_system.add_own_credits(5, user.id)
puts "own credits: #{accounting_system.own_credits(user.id)}"
puts "today allowance: #{accounting_system.calculate_credit_day_allowance(user.id)}"
puts "mon allowance: #{accounting_system.calculate_credit_day_allowance(user.id)}"
puts "tue allowance: #{accounting_system.calculate_credit_day_allowance(user.id, 'tue')}"