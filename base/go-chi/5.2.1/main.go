package main

import (
	"fmt"
	"log"
	"net"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func clientIP(remoteAddr string) string {
	host, _, err := net.SplitHostPort(remoteAddr)
	if err == nil {
		return host
	}
	return remoteAddr
}

func main() {
	router := chi.NewRouter()
	router.Use(middleware.RealIP)
	router.Get("/admin/secret", func(w http.ResponseWriter, r *http.Request) {
		if clientIP(r.RemoteAddr) != "127.0.0.1" {
			http.Error(w, "forbidden", http.StatusForbidden)
			return
		}
		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprintln(w, "vulhub-secret")
	})

	log.Println("Listening on :80")
	log.Fatal(http.ListenAndServe(":80", router))
}
