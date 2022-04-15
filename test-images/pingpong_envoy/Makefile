.PHONY: all pinpong clean

all: pinpong

pinpong:
	docker build -t sc-poc-pingpong-envoy:latest .

clean:
	docker rmi -f sc-poc-pingpong-envoy:latest