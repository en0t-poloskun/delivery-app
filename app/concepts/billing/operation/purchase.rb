module Billing::Operation
  class Purchase < Trailblazer::Operation
    step :validate_product
    step :gateway_purchase
    step :validate_purchase_result
    step :grant_access_to_product
    step :notify_about_product_access
    step :arrange_delivery
    step :validate_delivery_result
    step :create_delivery_info
    step :notify_about_delivery

    def validate_product(ctx, params)
      ctx[:error_message] = 'Product is not found'
      params[:product].present?
    end

    def gateway_purchase(ctx, params)
      ctx[:payment_result] = payment_gateway.proccess(
        user_uid: params[:user].cloud_payments_uid,
        amount_cents: params[:product].amount_cents,
        currency: 'RUB'
      )
    end

    def validate_purchase_result(ctx, params)
      ctx[:error_message] = ctx[:payment_result][:error]
      ctx[:payment_result][:status] == 'completed'
    end

    def grant_access_to_product(ctx, params)
      ctx[:product_access] = ProductAccess.create(
        user: params[:user],
        product: params[:product]
      )
    end

    def notify_about_product_access(ctx, params)
      OrderMailer.product_access_email(ctx[:product_access]).deliver_later
    end

    def arrange_delivery(ctx, params)
      ctx[:delivery_result] = delivery_service.setup_delivery(
        address: params[:user].address,
        person: params[:user],
        weight: params[:product].weight
      )
    end

    def validate_delivery_result(ctx, params)
      ctx[:error_message] = 'Something went wrong during the delivery process'
      ctx[:delivery_result][:result] == 'succeed'
    end

    def create_delivery_info(ctx, params)
      ctx[:product_delivery] = ProductDelivery.create(
        user: params[:user],
        product: params[:product],
        delivery_service: delivery_service.to_s
      )
    end

    def notify_about_delivery
      OrderMailer.product_delivery_email(ctx[:product_delivery]).deliver_later
    end

    def payment_gateway
      CloudPayment
    end

    def delivery_service
      Sdek
    end
  end
end
