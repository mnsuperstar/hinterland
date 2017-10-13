ActiveAdmin.register_page "Charts" do
  menu parent: 'dashboard'

  content title: "Chart" do
    div do
      table class: "index_table" do
        thead do
          tr do th do "Bookings over time (past 30 days)" end end
        end
        tbody do
          tr do td do
            area_chart Booking.group_by_day(:created_at, range: 1.months.ago..Time.now).count,
                width: "900px", height: "400px"
          end end
        end
      end
    end
    div do
      table class: "index_table" do
        thead do
          tr do th do "New guides over time (past 30 days)" end end
        end
        tbody do
          tr do td do
            area_chart User.guides.group_by_day('users.created_at', range: 1.months.ago..Time.now).count,
                width: "900px", height: "400px"
          end end
        end
      end
    end
    div do
      table class: "index_table" do
        thead do
          tr do th do "New adventurers over time (past 30 days)" end end
        end
        tbody do
          tr do td do
            area_chart User.adventurers.group_by_day('users.created_at', range: 1.months.ago..Time.now).count,
                width: "900px", height: "400px"
          end end
        end
      end
    end
    div do
      table class: "index_table" do
        thead do
          tr do th do "Total transactions (past 30 days)" end end
        end
        tbody do
          tr do td do
            area_chart Booking.accepted.group_by_day('accepted_at', range: 1.months.ago..Time.now).sum('total_price_cents / 100'),
                ytitle: "USD",
                width: "900px", height: "400px"
          end end
        end
      end
    end
    div do
      table class: "index_table" do
        thead do
          tr do th do "Average guide revenues" end end
        end
        tbody do
          tr do td do
            area_chart User.guides.group('users.email').joins(:received_charges).average('(charges.amount_cents - charges.fee_cents) / 100'),
                ytitle: "USD",
                width: "900px", height: "400px"
          end end
        end
      end
    end
    div do
      table class: "index_table" do
        thead do
          tr do
            th do "User Agent for Account Creation group by Browser" end
            th do "User Agent for Account Creation group by Platform" end
          end
        end
        tbody do
          tr do
            td do
              area_chart Agent.count_user_agents_browser('user'),
                  xtitle: "Browser", ytitle: "Number of creators",
                  width: "400px", height: "400px"
            end
            td do
              area_chart Agent.count_user_agents_platform('user'),
                xtitle: "Platform", ytitle: "Number of creators",
                width: "400px", height: "400px"
            end
          end
        end
      end
    end
    div do
      table class: "index_table" do
        thead do
          tr do
            th do "User Agent for Booking Creation group by Browser" end
            th do "User Agent for Booking Creation group by Platform" end
          end
        end
        tbody do
          tr do
            td do
              area_chart Agent.count_user_agents_browser('booking'),
                  xtitle: "Browser", ytitle: "Number of creators",
                  width: "400px", height: "400px"
            end
            td do
              area_chart Agent.count_user_agents_platform('booking'),
                xtitle: "Platform", ytitle: "Number of creators",
                width: "400px", height: "400px"
            end
          end
        end
      end
    end
  end
end
