module LeadsHelper
  def lead_status_label(status)
    # see: http://getbootstrap.com/components/#available-variations
    label_type = case status
                 when 'pending' then 'warning'
                 when 'quality_check' then 'info'
                 when 'approved' then 'success'
                 when 'rejected' then 'danger'
                 when 'invoiced' then 'primary'
                 end
    content_tag :span, status.titleize, class: "label label-#{label_type}"
  end
end
