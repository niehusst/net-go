package instrumentation

import (
	"context"
	"net-go/server/backend/constants"

	"github.com/uptrace/opentelemetry-go-extra/otelgorm"
	"go.opentelemetry.io/otel"
	"gorm.io/gorm"
)

func InstrumentDbConnection(db *gorm.DB) {
	if constants.GetDevMode() {
		return
	}
	if err := db.Use(otelgorm.NewPlugin()); err != nil {
		panic(err)
	}
}

/**
 * Starts a trace span with the given `name`.
 *
 * @returns ctx - a Context that should be used with gorm.DB calls to be traced
 * 		 endSpan - a function for ending the trace span
 */
func StartDbTrace(name string) (context.Context, func()) {
	trace := otel.Tracer(constants.GetOtelServiceName())
	ctx, span := trace.Start(context.Background(), name)
	return ctx, func() { span.End() }
}
