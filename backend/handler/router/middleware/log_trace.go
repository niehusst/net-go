package middleware

import (
	"github.com/gin-gonic/gin"
	"go.opentelemetry.io/otel/trace"
	"go.uber.org/zap"
)

func AttachLogTraceMetadata() gin.HandlerFunc {
	return func(c *gin.Context) {
		spanContext := trace.SpanContextFromContext(c)
		logger := zap.L()
		// attach trace id to the log
		if spanContext.IsValid() {
			logger = logger.With(
				zap.String("trace_id", spanContext.TraceID().String()),
				zap.String("span_id", spanContext.SpanID().String()),
			)
			zap.ReplaceGlobals(logger)
		}

		c.Next()
	}
}
