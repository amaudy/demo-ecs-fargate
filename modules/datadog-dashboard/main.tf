terraform {
  required_providers {
    datadog = {
      source = "DataDog/datadog"
    }
  }
}

resource "datadog_dashboard" "alb_monitoring" {
  title       = "ALB Monitoring - ${var.environment}"
  description = "Dashboard for monitoring Application Load Balancer metrics and logs"
  layout_type = "ordered"

  widget {
    timeseries_definition {
      title = "Request Count"
      request {
        q = "sum:aws.applicationelb.request_count{loadbalancer:app/${var.alb_name}/*}.as_count()"
        display_type = "bars"
      }
      yaxis {
        include_zero = true
        scale       = "linear"
      }
    }
  }

  widget {
    query_value_definition {
      title = "Success Rate (2xx)"
      precision = 2
      request {
        q = "100 * sum:aws.applicationelb.httpcode_target_2xx_count{loadbalancer:app/${var.alb_name}/*} / sum:aws.applicationelb.request_count{loadbalancer:app/${var.alb_name}/*}"
        aggregator = "last"
        conditional_formats {
          comparator = "<"
          value      = "95"
          palette    = "white_on_red"
        }
        conditional_formats {
          comparator = ">="
          value      = "95"
          palette    = "white_on_green"
        }
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Response Codes"
      request {
        q = "sum:aws.applicationelb.httpcode_target_2xx_count{loadbalancer:app/${var.alb_name}/*}.as_count(), sum:aws.applicationelb.httpcode_target_3xx_count{loadbalancer:app/${var.alb_name}/*}.as_count(), sum:aws.applicationelb.httpcode_target_4xx_count{loadbalancer:app/${var.alb_name}/*}.as_count(), sum:aws.applicationelb.httpcode_target_5xx_count{loadbalancer:app/${var.alb_name}/*}.as_count()"
        display_type = "bars"
      }
      yaxis {
        include_zero = true
        scale       = "linear"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Latency (seconds)"
      request {
        q = "avg:aws.applicationelb.target_response_time.average{loadbalancer:app/${var.alb_name}/*}, avg:aws.applicationelb.target_response_time.p90{loadbalancer:app/${var.alb_name}/*}, avg:aws.applicationelb.target_response_time.p95{loadbalancer:app/${var.alb_name}/*}, avg:aws.applicationelb.target_response_time.p99{loadbalancer:app/${var.alb_name}/*}"
        display_type = "line"
      }
      yaxis {
        include_zero = true
        scale       = "linear"
        min = "0"
        max = "2"
      }
    }
  }

  widget {
    toplist_definition {
      title = "Top Request Paths"
      request {
        q = "top(aws.applicationelb.request_count{loadbalancer:app/${var.alb_name}/*} by {request_path}, 10, 'last', 'desc')"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "5xx Errors"
      request {
        q = "sum:aws.applicationelb.httpcode_target_5xx_count{loadbalancer:app/${var.alb_name}/*}.as_count()"
        display_type = "bars"
      }
      yaxis {
        include_zero = true
        scale       = "linear"
      }
    }
  }

  widget {
    log_stream_definition {
      title = "Recent ALB Logs"
      indexes = ["*"]
      query = "source:aws.alb service:alb env:development project:dd-demo project_code:abc1234 @timestamp:>now-15m"
      columns = ["@timestamp", "host", "@http.method", "@http.url", "@http.status_code", "@duration"]
      show_date_column = true
      show_message_column = true
      message_display = "expanded-md"
      sort {
        column = "@timestamp"
        order = "desc"
      }
    }
  }

  widget {
    toplist_definition {
      title = "Top Browsers"
      request {
        q = "top(count:alb.http.request{service:ecom-api} by {http.user_agent}, 10, 'last', 'desc')"
      }
      style {
        palette = "dog_classic"
      }
    }
  }

  widget {
    pie_definition {
      title = "Browser Distribution"
      request {
        query {
          metric_query = "count:alb.http.request{service:ecom-api} by {http.user_agent}"
          aggregator = "sum"
        }
      }
      style {
        palette = "cool"
      }
    }
  }

  tags = var.tags
}
