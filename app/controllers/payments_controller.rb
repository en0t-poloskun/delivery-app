class PaymentsController < ApplicationController
  def create
    product = Product.find_by(id: params[:product_id])
    purchase_result = Billing::Operation::Purchase.call(params: { user: current_user, product: product })

    if purchase_result.successful?
      redirect_to :successful_payment_path
    else
      redirect_to :failed_payment_path, note: purchase_result[:error_message]
    end
  end
end
