.PHONY: build
build:
	GOOS=linux go build -o build/ca-token-generator main.go
	docker build -t greytip/nifi-ca-token-generator .
	docker push greytip/nifi-ca-token-generator
