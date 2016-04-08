updateUserForm = ($role)->
  companyFields = ['#user_company_name_input', '#user_company_weburl_input', '#user_company_description_input']
  personFields = ['#user_first_name_input', '#user_last_name_input', '#user_title_input']
  currentRole = $role.find('option:selected').text()
  if currentRole == 'COMPANY'
    $.each companyFields, (i, selector)->
      $(selector).show().find('input,textarea,select').removeAttr('disabled')
    $.each personFields, (i, selector)->
      $(selector).hide().find('input,textarea,select').attr('disabled', 'disabled')
  else
    $.each companyFields, (i, selector)->
      $(selector).hide().find('input,textarea,select').attr('disabled', 'disabled')
    $.each personFields, (i, selector)->
      $(selector).show().find('input,textarea,select').removeAttr('disabled')

$(document).ready ->
  $role = $('select#user_role')
  updateUserForm($role)
  $role.change ->
    updateUserForm($(this))