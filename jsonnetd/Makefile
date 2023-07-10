tag = 0.8

image:
	docker build -t primeroz/jsonnetd:$(tag) --build-arg version=$(tag) .

push: image
	docker push primeroz/jsonnetd:$(tag)

build:
	go build -ldflags="-X 'main.Version=local-$(tag)'"

