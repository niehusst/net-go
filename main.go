package main

import (
	"context"
	"fmt"
	"log"
	"net-go/server/backend/constants"
	"net-go/server/backend/handler/provider"
	"net-go/server/backend/handler/router"
	"net-go/server/backend/services"
	"net-go/server/backend/subscriptions"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/hyperdxio/opentelemetry-go/otelzap"
	"github.com/hyperdxio/opentelemetry-logs-go/exporters/otlp/otlplogs"
	sdk "github.com/hyperdxio/opentelemetry-logs-go/sdk/logs"
	"github.com/hyperdxio/otel-config-go/otelconfig"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

func buildLogger() func() {
	// Initialize otel config and use it across the entire app
	otelShutdown, err := otelconfig.ConfigureOpenTelemetry()
	if err != nil {
		log.Fatalf("error setting up OTel SDK: %e", err)
	}

	ctx := context.Background()

	// configure opentelemetry logger provider
	logExporter, err := otlplogs.NewExporter(ctx)
	if err != nil {
		log.Fatalf("OTLP exporter init failed: %e", err)
	}
	loggerProvider := sdk.NewLoggerProvider(
		sdk.WithBatcher(logExporter),
	)

	// create new logger with opentelemetry zap core and set it globally
	var logger *zap.Logger
	if constants.GetDevMode() {
		logger = zap.Must(zap.NewDevelopment(zap.Development(), zap.AddCallerSkip(1)))
	} else {
		logger = zap.New(otelzap.NewOtelCore(loggerProvider), zap.AddCallerSkip(1))
	}
	zap.ReplaceGlobals(logger)

	// gracefully shutdown logger to flush accumulated signals before program finish
	return func() {
		otelShutdown()
		loggerProvider.Shutdown(ctx)
	}
}

func buildProvider() provider.Provider {
	dbStr := fmt.Sprintf(
		"%s:%s@tcp(%s:3306)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		constants.GetDatabaseUserUsername(),
		constants.GetDatabaseUserPassword(),
		constants.GetDatabaseHost(),
		constants.GetDatabaseName(),
	)
	baseRepoDeps := &services.BaseRepoDeps{
		DbString: dbStr,
		Config:   &gorm.Config{},
	}
	userDeps := services.UserServiceDeps{
		UserRepository: services.NewUserRepository(
			&services.UserRepoDeps{
				BaseDeps: baseRepoDeps,
			},
		),
	}
	gameDeps := services.GameServiceDeps{
		GameRepository: services.NewGameRepository(
			&services.GameRepoDeps{
				BaseDeps: baseRepoDeps,
			},
		),
	}
	p := provider.Provider{
		R:             gin.Default(),
		UserService:   services.NewUserService(userDeps),
		GameService:   services.NewGameService(gameDeps),
		Subscriptions: make(subscriptions.GameSubscriptions),
	}

	// TODO: do this separately...?
	// migrate db
	if err := p.MigrateAll(); err != nil {
		log.Printf("Failed to auto migrate db: %v\n", err)
		panic("Migration failure!")
	}
	return p
}

func main() {
	constants.LoadEnv()
	port := ":" + constants.GetPort()
	log.Println("Starting server...")

	p := buildProvider()

	// setup logging
	shutdownLogger := buildLogger()
	defer shutdownLogger()

	// set routing and server config
	router.SetRouter(p)
	srv := &http.Server{
		Addr:    port,
		Handler: p.R,
	}

	log.Println("Listening on port", port)

	// Initializing the server in a goroutine so that
	// it won't block the graceful shutdown handling below
	// https://github.com/gin-gonic/examples/blob/master/graceful-shutdown/graceful-shutdown/notify-without-context/server.go
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %s\n", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server with
	// a timeout of 5 seconds.
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	// this blocks until `quit` channel receives a kill signal
	<-quit
	log.Println("Shutting down server...")

	// close subscriptions to allow long-poll requests to finish
	for _, subscription_chan := range p.Subscriptions {
		close(subscription_chan)
	}

	// The context is used to inform the server it has 5 seconds to finish
	// the request it is currently handling
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown: ", err)
	}

	log.Println("Server exiting")
}
