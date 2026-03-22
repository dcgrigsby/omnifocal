package main

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

func main() {
	addr := serverAddr()

	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/eval", evalHandler)

	log.SetOutput(os.Stderr)
	log.Printf("omnifocal-server listening on %s", addr)

	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("server failed: %v", err)
	}
}

func serverAddr() string {
	if addr := os.Getenv("OMNIFOCAL_ADDR"); addr != "" {
		return addr
	}
	return "0.0.0.0:7890"
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, "ok")
}

func evalHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		writePlainText(w, http.StatusInternalServerError, fmt.Sprintf("failed to read request body: %v", err))
		return
	}
	defer r.Body.Close()

	script := string(body)
	if strings.TrimSpace(script) == "" {
		writePlainText(w, http.StatusBadRequest, "empty request body")
		return
	}

	stdout, stderr, execErr := runOsaScript(script)
	if execErr != nil {
		errMsg := stderr
		if errMsg == "" {
			errMsg = execErr.Error()
		}
		writePlainText(w, http.StatusInternalServerError, errMsg)
		return
	}

	writePlainText(w, http.StatusOK, stdout)
}

func runOsaScript(script string) (string, string, error) {
	// Use AppleScript to invoke OmniFocus's built-in Omni Automation JS engine.
	// This gives us the full Omni Automation API (inbox, flattenedTasks, etc.)
	// rather than JXA's different Application("OmniFocus") bridge.
	escaped := strings.ReplaceAll(script, "\\", "\\\\")
	escaped = strings.ReplaceAll(escaped, "\"", "\\\"")
	appleScript := fmt.Sprintf(`tell application "OmniFocus" to evaluate javascript "%s"`, escaped)
	cmd := exec.Command("/usr/bin/osascript", "-e", appleScript)

	var stdoutBuf, stderrBuf bytes.Buffer
	cmd.Stdout = &stdoutBuf
	cmd.Stderr = &stderrBuf

	err := cmd.Run()
	return stdoutBuf.String(), stderrBuf.String(), err
}

func writePlainText(w http.ResponseWriter, status int, body string) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(status)
	fmt.Fprint(w, body)
}
