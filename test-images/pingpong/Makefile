.PHONY: all pinpong clean

all: pinpong

pinpong:
	docker build -t sc-poc-pingpong:latest .

clean:
	docker rmi -f sc-poc-pingpong:latest