module PrivateeBrokerHelper

  def privatee_broker_fee_text
    fee = BrokerInfo.privatee_broker_fee(session[:country])
    currency = fee[:currency].symbol
    res = "#{currency}#{fee[:price]}"
    res << " + VAT (#{currency}#{fee[:vat]})" if fee[:vat]
    res
  end

  def privatee_broker_pay_text
    fee = BrokerInfo.privatee_broker_fee(session[:country])
    currency = fee[:currency].symbol
    total = fee[:price] + (fee[:vat] || 0)
    "Pay #{currency}#{total}"
  end

end
