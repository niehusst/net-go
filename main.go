package main

import (
	"context"
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
	"gorm.io/gorm"
)

func main() {
	constants.LoadEnv()
	port := ":" + constants.GetPort()
	log.Println("Starting server...\nListening at port", port)

	// create service provider
	baseRepoDeps := services.BaseRepoDeps{
		DbString: constants.GetDatabaseURI(),
		Config:   &gorm.Config{},
	}
	userDeps := services.UserServiceDeps{
		UserRepository: services.NewUserRepository(
			&services.UserRepoDeps{
				BaseRepoDeps: baseRepoDeps,
			},
		),
	}
	gameDeps := services.GameServiceDeps{
		GameRepository: services.NewGameRepository(
			&services.GameRepoDeps{
				BaseRepoDeps: baseRepoDeps,
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

	// set routing and server config
	router.SetRouter(p)
	srv := &http.Server{
		Addr:    port,
		Handler: p.R,
	}

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

	// The context is used to inform the server it has 5 seconds to finish
	// the request it is currently handling
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown: ", err)
	}

	log.Println("Server exiting")
}
