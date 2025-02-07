resource "datadog_dashboard" "top5_paths" {
  title       = "${var.service_name} - Top 5 Paths Dashboard (${var.environment})"
  description = "Shows top 5 most requested paths and related metrics for ${var.service_name}"
  layout_type = "ordered"

  widget {
    toplist_definition {
      title = "Top 5 Most Requested Paths"
      request {
        q = "top(sum:alb.http.request.count{service:${var.service_name}} by {http.url}, 5, 'sum', 'desc')"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Request Count by Path (Top 5)"
      request {
        q = "top(sum:alb.http.request.count{service:${var.service_name}} by {http.url}, 5, 'sum', 'desc')"
        display_type = "line"
      }
    }
  }

  widget {
    query_value_definition {
      title = "Total Requests (Last 15 minutes)"
      precision = 0
      request {
        q = "sum:alb.http.request.count{service:${var.service_name}}.rollup(sum, 900)"
      }
    }
  }

  widget {
    query_table_definition {
      title = "Status Code Distribution by Path"
      request {
        q = "top(sum:alb.http.request.count{service:${var.service_name}} by {http.url,http.status_code}, 10, 'sum', 'desc')"
      }
    }
  }

  widget {
    toplist_definition {
      title = "Top 10 Browsers"
      request {
        q = "top(sum:alb.http.request.count{service:${var.service_name}} by {http.user_agent}, 10, 'sum', 'desc')"
      }
      custom_link {
        label = "View All Browsers"
        link  = "https://us5.datadoghq.com/logs?query=service:${var.service_name}"
      }
    }
  }

  widget {
    group_definition {
      title = "Browser Usage Statistics"
      layout_type = "ordered"
      
      widget {
        timeseries_definition {
          title = "Browser Distribution Over Time"
          request {
            q = "top(sum:alb.http.request.count{service:${var.service_name}} by {http.user_agent}, 5, 'sum', 'desc')"
            display_type = "area"
          }
        }
      }

      widget {
        query_table_definition {
          title = "Browser Statistics"
          request {
            q = "top(sum:alb.http.request.count{service:${var.service_name}} by {http.user_agent}, 10, 'sum', 'desc')"
            conditional_formats {
              comparator = ">"
              value = 0
              palette = "white_on_green"
            }
          }
        }
      }
    }
  }

  tags = ["team:devops"]
}
