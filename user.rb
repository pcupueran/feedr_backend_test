class User
  attr_reader :email, :id
  def initialize(id, email)
    @email = email
    @id = id
  end
end