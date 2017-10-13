ActiveAdmin.register StripePlan do
  menu parent: 'dashboard'
  actions :all, except: %i(show)

  permit_params :plan_type, :trial_period_days, :amount_cents

  index do
    selectable_column
    id_column
    column :plan_type
    column :trial_period_days
    column :amount_cents
    actions
  end

  form do |f|
    f.inputs do
      f.input :plan_type, as: :radio, collection: StripePlan.plan_types.keys
      if f.object.new_record?
        f.input :trial_period_days, hint: 'Specifies a trial period in days.'
        f.input :amount_cents, hint: 'The amount in cents to be charged per-month'
      end
    end
    f.actions
  end
end
