ActiveAdmin.register Newsletter do
  menu parent: 'users'

  permit_params :email

end
