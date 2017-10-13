ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  action_item :re_seed do
    if !Rails.env.production? && ENV['ALLOW_RE_SEED']
      link_to 'DB Re-Seed', admin_dashboard_re_seed_path, method: :put, data: { confirm: "This action will replace data with those generated in seeds, continue?" }
    end
  end

  action_item :guides_awaiting_approved do
    link_to "Pending Guides (#{User.unverified_guides.count})", admin_guides_path(scope: 'unverified_guides')
  end

  content title: proc{ I18n.t("active_admin.dashboard") } do
    div do
      table class: "index_table" do
        thead do
          tr do th do "Number of guides per location (per state)" end end
        end
        tbody do
          tr do td do
            column_chart User.guides.joins(adventures: :location).group('locations.state').distinct.count,
                   xtitle: "Location", ytitle: "Number of Guides",
                   width: "900px", height: "400px"
          end end
        end
      end
    end
    div do
      table class: "index_table" do
        thead do
          tr do th do "Activities popularity" end end
        end
        tbody do
          tr do td do
            column_chart Adventure.joins(:activities).group('activities.title').order('activities.title').count,
                 xtitle: "Activity", ytitle: "Number of Adventures",
                 width: "900px", height: "400px"
          end end
        end
      end
    end

    panel "Statistics" do
      table do
        thead do
          tr do
            th "Number of bookings"
            th "Number of chats"
            th "Number of messages"
            th "Number of users"
          end
        end
        tbody do
          tr do
            td Booking.count
            td Chat.count
            td Message.count
            td User.count
          end
        end
      end
    end
  end # content

  page_action :re_seed, method: :put do
    ReSeedJob.perform_later
    redirect_back fallback_location: admin_dashboard_path, notice: "Re-seed scheduled."
  end
end
