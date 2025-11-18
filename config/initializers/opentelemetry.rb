# OpenTelemetry initialization
require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"
require "opentelemetry/instrumentation/rails"
require "opentelemetry-metrics-sdk"
require "opentelemetry-exporter-otlp-metrics"
require "opentelemetry-logs-sdk"
require "opentelemetry-exporter-otlp-logs"

# Configure OpenTelemetry SDK
OpenTelemetry::SDK.configure do |c|
  c.service_name = ENV.fetch("OTEL_SERVICE_NAME", "buildboard")
  c.use "OpenTelemetry::Instrumentation::Rails"
end

# Configure Metrics
otlp_metric_exporter = OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter.new
OpenTelemetry.meter_provider.add_metric_reader(otlp_metric_exporter)

# Global meter for application metrics
OTEL_METER = OpenTelemetry.meter_provider.meter("buildboard")

# Global logger for application logs
OTEL_LOGGER = OpenTelemetry.logger_provider.logger(name: "buildboard")

# Global tracer
OTEL_TRACER = OpenTelemetry.tracer_provider.tracer("buildboard")