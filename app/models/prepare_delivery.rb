class PrepareDelivery
  TRUCKS = { kamaz: 3000, gazel: 1000 }.freeze

  ValidationError = Class.new StandardError

  def initialize(order, user, destination_address, delivery_date)
    @order = order
    @user = user
    @destination_address = destination_address
    @delivery_date = delivery_date
  end

  def perform
    validate_delivery_date!
    validate_adress_presence!
    validate_truck_presence!

    prepare_delivery_result
  rescue ValidationError
    prepare_delivery_result[:status] = :error
    prepare_delivery_result
  end

  private

  def validate_delivery_date!
    raise ValidationError, 'The delivery date has already passed' if @delivery_date < Time.current
  end

  def validate_adress_presence!
    if @destination_address.city.empty? || @destination_address.street.empty? || @destination_address.house.empty?
      raise ValidationError, 'No address'
    end
  end

  def validate_truck_presence!
    raise ValidationError, 'No truck' if truck.nil?
  end

  def weight
    @weight ||= @order.products.map(&:weight).sum
  end

  def truck
    @truck ||= TRUCKS.select { |_key, value| value > weight }.keys.last
  end

  def prepare_delivery_result
    @prepare_delivery_result ||=
      {
        truck: truck,
        weight: weight,
        order_number: @order.id,
        address: @destination_address,
        status: :ok
      }
  end
end
