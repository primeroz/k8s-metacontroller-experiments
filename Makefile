.ONESHELL: # Applies to every targets in the file!

.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

.PHONY: run
run: # Run the project
	@./kind.sh exists || ./kind.sh create
	@source ./common ;\
  e_header "Creating MetaController" ;\
  kubectl apply -k metacontroller/ ;\
  e_success "Done"

.PHONY: clean
clean: # Clean the project
	@./kind.sh delete

.PHONY: apply_random_secrets_controllers
apply_random_secrets_controllers:
	@make -C random-secret-controller apply_manifests

.PHONY: apply_mqtt_pipeline_controller
apply_mqtt_pipeline_controller:
	@make -C mqtt-pipeline-controller apply_manifests

.PHONY: apply_controllers
apply_controllers: apply_random_secrets_controllers apply_mqtt_pipeline_controller
