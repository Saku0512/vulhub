package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func main() {
	router := chi.NewRouter()
	// This lab has no reverse proxy, so the socket peer is the only trusted
	// source of the client address. X-Forwarded-For must be ignored.
	router.Use(middleware.ClientIPFromRemoteAddr)
	router.Get("/admin/secret", func(w http.ResponseWriter, r *http.Request) {
		if middleware.GetClientIP(r.Context()) != "127.0.0.1" {
			http.Error(w, "forbidden", http.StatusForbidden)
			return
		}
		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprintln(w, "vulhub-secret")
	})

	log.Println("Listening on :80")
	log.Fatal(http.ListenAndServe(":80", router))
}
