package main

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"
)

const (
	ec2IMDSUrl        = "http://169.254.169.254"
	ecsTMDSV2Url      = "http://169.254.170.2/v2/metadata"
	httpClientTimeout = 10 * time.Second
	pingOrPong        = "PING_OR_PONG"
)

func main() {
	action := os.Getenv(pingOrPong)
	log.Printf("%s server starting up...\n", action)
	err := initServer()
	if err != nil {
		log.Printf("%s server got error when initializing: %v\n", action, err)
		os.Exit(1)
	}
	wg := new(sync.WaitGroup)
	wg.Add(2)
	go func() {
		defer wg.Done()
		server := createServer(8080, pingPongSC)
		log.Println(server.ListenAndServe())
	}()

	go func() {
		defer wg.Done()
		server := createServer(9090, otherNonSC)
		log.Println(server.ListenAndServe())
	}()
	wg.Wait()
	log.Printf("%s server done", action)
	os.Exit(0)
}

func createServer(port int, handlerFunc func(w http.ResponseWriter, req *http.Request)) *http.Server {
	mux := http.NewServeMux()
	mux.HandleFunc("/", handlerFunc)
	return &http.Server{
		Addr:    fmt.Sprintf(":%v", port),
		Handler: mux,
	}
}

func otherNonSC(w http.ResponseWriter, req *http.Request) {
	log.Printf("request headers: %v\n", req.Header)
	fmt.Fprint(w, "Hello from a Non-SC service")
}
func pingPongSC(w http.ResponseWriter, req *http.Request) {
	log.Printf("request headers: %v\n", req.Header)
	body, err := ioutil.ReadAll(req.Body)
	if err != nil {
		log.Printf("failed to get request body: %v\n", err)
	}
	bodyStr := string(body)
	log.Printf("received %s (%s)\n", bodyStr, req.RemoteAddr)

	bodyArr := strings.Split(bodyStr, " ")
	var response string
	if bodyArr[0] == "PING" {
		response = "PONG from pong.my.corp:8080"
	} else {
		response = "PING from ping.my.corp:8080"
	}
	sendResponse(response, bodyArr[2])
}

func sendResponse(response, to string) {
	log.Printf("senging '%s' to %s\n", response, to)
	time.Sleep(time.Second)
	resp, err := http.Post("http://"+to+"", "text/html; charset=UTF-8", bytes.NewBuffer([]byte(response)))
	if err != nil {
		log.Printf("Error sending '%s' to %s: %v\n", response, to, err)
		return
	}
	defer resp.Body.Close()
}

func initServer() error {
	region, err := getRegionFromIMDS()
	if err != nil {
		log.Printf("error getting region from IMDS due to error: %v. setting to us-west-2 and continue checking the rest\n", err)
		region = "us-west-2"
	} else {
		log.Printf("got region from imds: %s\n", region)
	}

	md, err := getTaskMetadata()
	if err != nil {
		return err
	}

	log.Printf("got task metadata: %s\n", md)
	return nil
}

func getRegionFromIMDS() (string, error) {
	log.Println("getting region from imds")
	httpClient := &http.Client{
		Timeout: httpClientTimeout,
	}
	return getIMDSV1(httpClient, "/latest/meta-data/placement/region")
}

func getIMDSV1(httpClient *http.Client, mdSuffix string) (string, error) {
	regionUrl := fmt.Sprintf("%s%s", ec2IMDSUrl, mdSuffix)
	req, err := http.NewRequest("GET", regionUrl, nil)
	if err != nil {
		return "", fmt.Errorf("unable to create get region request: %w", err)
	}
	resp, err := httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("unable to get region from imds: %w", err)
	}
	defer resp.Body.Close()

	region, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("unable to read region from response: %w", err)
	}

	return string(region), nil
}

func getTaskMetadata() (string, error) {
	log.Println("verifying task metadata")

	resp, err := http.Get(ecsTMDSV2Url)
	if err != nil {
		return "", fmt.Errorf("unable to make request to task metadata endpoint: %w", err)
	}

	md, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("unable to read metadata from response: %w", err)
	}

	return string(md), nil
}
