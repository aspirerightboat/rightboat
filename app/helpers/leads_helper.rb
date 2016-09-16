module LeadsHelper
  def lead_status_label(status)
    # see: http://getbootstrap.com/components/#available-variations
    label_type = case status
                 when 'pending' then 'warning'
                 when 'quality_check' then 'info'
                 when 'approved' then 'success'
                 when 'cancelled' then 'danger'
                 when 'invoiced' then 'primary'
                 end
    content_tag :span, status.titleize, class: "label label-#{label_type}"
  end

  def approved_percentage(total, approved)
    total > 0 ? "#{((approved.to_f / total) * 10000).round.to_f / 100} %" : '-'
  end

  def lead_phone(lead)
    if lead.country_code.present?
      "+#{lead.country_code} #{lead.phone}"
    else
      lead.phone
    end
  end
end
