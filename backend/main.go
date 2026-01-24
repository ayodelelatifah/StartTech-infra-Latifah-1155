package main

import (
	"fmt"
	"net/http"
)

func main() {
	// Root endpoint
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, StartTech!")
	})

	// Health check endpoint for AWS Load Balancer
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "OK")
	})

	http.ListenAndServe(":8080", nil)
}