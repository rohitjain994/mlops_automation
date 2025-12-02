CLUSTER_NAME := argo-cluster
KUBECTL := kubectl
KIND := kind
ARGO_NAMESPACE := argo

.PHONY: all install-tools cluster argo infra submit verify clean

all: cluster argo infra

install-tools:
	@echo "Checking and installing dependencies..."
	# Install Kind
	@if ! command -v kind >/dev/null 2>&1; then \
		echo "Installing Kind..."; \
		curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-$(shell uname -s | tr '[:upper:]' '[:lower:]')-amd64; \
		chmod +x ./kind; \
		sudo mv ./kind /usr/local/bin/kind; \
	else \
		echo "Kind is already installed."; \
	fi
	# Install Kubectl
	@if ! command -v kubectl >/dev/null 2>&1; then \
		echo "Installing Kubectl..."; \
		curl -LO "https://dl.k8s.io/release/$(shell curl -L -s https://dl.k8s.io/release/stable.txt)/bin/$(shell uname -s | tr '[:upper:]' '[:lower:]')/amd64/kubectl"; \
		chmod +x kubectl; \
		sudo mv kubectl /usr/local/bin/; \
	else \
		echo "Kubectl is already installed."; \
	fi
	# Install Argo CLI
	@if ! command -v argo >/dev/null 2>&1; then \
		echo "Installing Argo CLI..."; \
		curl -sLO https://github.com/argoproj/argo-workflows/releases/download/v3.5.2/argo-$(shell uname -s | tr '[:upper:]' '[:lower:]')-amd64.gz; \
		gunzip argo-$(shell uname -s | tr '[:upper:]' '[:lower:]')-amd64.gz; \
		chmod +x argo-$(shell uname -s | tr '[:upper:]' '[:lower:]')-amd64; \
		sudo mv argo-$(shell uname -s | tr '[:upper:]' '[:lower:]')-amd64 /usr/local/bin/argo; \
	else \
		echo "Argo CLI is already installed."; \
	fi
	@echo "Dependency check complete."

cluster:
	@echo "Creating Kind cluster..."
	$(KIND) create cluster --name $(CLUSTER_NAME) || echo "Cluster might already exist"
	$(KUBECTL) cluster-info --context kind-$(CLUSTER_NAME)

argo:
	@echo "Installing Argo Workflows..."
	$(KUBECTL) create namespace $(ARGO_NAMESPACE) || echo "Namespace $(ARGO_NAMESPACE) already exists"
	$(KUBECTL) apply -n $(ARGO_NAMESPACE) -f https://github.com/argoproj/argo-workflows/releases/download/v3.5.2/install.yaml
	@echo "Waiting for Argo Server to be ready..."
	$(KUBECTL) wait --for=condition=Available deployment/argo-server -n $(ARGO_NAMESPACE) --timeout=300s
	@echo "Argo Workflows installed."

infra:
	@echo "Setting up infrastructure (PVC)..."
	$(KUBECTL) apply -n $(ARGO_NAMESPACE) -f manifests/pvc.yaml
	# Grant admin permissions to default SA for Argo Workflow execution
	$(KUBECTL) create rolebinding default-admin --clusterrole=admin --serviceaccount=$(ARGO_NAMESPACE):default -n $(ARGO_NAMESPACE) || echo "RoleBinding already exists"
	@echo "Infrastructure setup complete."

submit:
	@echo "Submitting Training Workflow..."
	argo submit -n $(ARGO_NAMESPACE) --watch workflows/train-workflow.yaml
	@echo "Workflow completed."

verify:
	@echo "Waiting for Model Serving Deployment..."
	$(KUBECTL) wait --for=condition=Available deployment/model-serving -n $(ARGO_NAMESPACE) --timeout=300s
	@echo "Model Serving is ready."
	@echo "Pod Status:"
	$(KUBECTL) get pods -n $(ARGO_NAMESPACE) -l app=model-serving
	@echo "Pod Logs:"
	$(KUBECTL) logs -n $(ARGO_NAMESPACE) -l app=model-serving --tail=20
	@echo "Service Status:"
	$(KUBECTL) get svc -n $(ARGO_NAMESPACE) model-service
	@echo "Service Endpoints:"
	$(KUBECTL) get endpoints -n $(ARGO_NAMESPACE) model-service
	@echo "Testing endpoint (in-cluster)..."
	# Run a temporary curl pod to test the service internally with retries
	$(KUBECTL) run curl-test --image=curlimages/curl --restart=Never -n $(ARGO_NAMESPACE) --rm -i -- curl -v --retry 10 --retry-delay 2 --retry-connrefused http://model-service:5000/health
	$(KUBECTL) run curl-predict --image=curlimages/curl --restart=Never -n $(ARGO_NAMESPACE) --rm -i -- curl -v --retry 10 --retry-delay 2 --retry-connrefused -X POST http://model-service:5000/predict -H 'Content-Type: application/json' -d '{"features": [0.5, -1.2, 3.3, 0.1]}'
	@echo "Verification successful."

clean:
	@echo "Deleting Kind cluster..."
	$(KIND) delete cluster --name $(CLUSTER_NAME)

uninstall-tools:
	@echo "Uninstalling tools..."
	sudo rm -f /usr/local/bin/kind
	sudo rm -f /usr/local/bin/kubectl
	sudo rm -f /usr/local/bin/argo
	@echo "Tools uninstalled."