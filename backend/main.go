package main

import (
    "fmt"
    "net/http"
    "os"
)

func main() {
    // 1. Health Check Endpoint (Required for ECS/ALB)
    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        fmt.Fprintln(w, "OK")
    })

    // 2. Simple API Response
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello from StartTech Backend! Environment: %s", os.Getenv("ENVIRONMENT"))
    })

    port := "8080"
    fmt.Printf("Server starting on port %s...\n", port)
    if err := http.ListenAndServe(":"+port, nil); err != nil {
        fmt.Printf("Failed to start server: %v\n", err)
    }
}