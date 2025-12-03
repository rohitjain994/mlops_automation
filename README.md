# MLOps Infrastructure Automation

This repository contains the complete automation for an MLOps pipeline using **Argo Workflows** on **Kubernetes**. It automates the end-to-end process of training a machine learning model and deploying it as a scalable web service.

## 🚀 Features

- **Automated Infrastructure**: One-click setup of a local Kubernetes cluster (Kind) with Argo Workflows installed.
- **Workflow Orchestration**: A DAG (Directed Acyclic Graph) workflow that manages dependencies between training and serving.
- **Training Step**:
  - Generates a dummy dataset.
  - Trains a Logistic Regression model (`scikit-learn`).
  - Saves the trained model artifact to a Persistent Volume (PVC).
- **Serving Step**:
  - Deploys a **FastAPI** application to serve the model.
  - Clones the repository at runtime to fetch the latest serving code.
  - Exposes a REST API (`/predict`, `/health`) via a Kubernetes Service.
- **CI/CD**: GitHub Actions pipeline that tests the entire flow (Infrastructure -> Train -> Serve -> Verify) on every push.

## 📂 Project Structure

```
mlops_automation/
├── .github/workflows/   # CI/CD Pipeline
├── manifests/           # Kubernetes Manifests
│   ├── pvc.yaml               # PersistentVolumeClaim for model storage
│   ├── serve-deployment.yaml  # Model Serving Deployment
│   └── serve-service.yaml     # Model Serving Service
├── scripts/             # Python Scripts
│   ├── train.py               # Training logic
│   └── serve.py               # FastAPI serving logic
├── workflows/           # Argo Workflow Definitions
│   └── train-workflow.yaml    # Main DAG (Train -> Serve)
├── Makefile             # Automation commands
└── README.md            # Project Documentation
```

## 🛠 Prerequisites

- Docker
- Git

The `Makefile` will automatically check for and install the following tools if they are missing:
- `kind` (Kubernetes in Docker)
- `kubectl` (Kubernetes CLI)
- `argo` (Argo Workflows CLI)

## ⚡ Quick Start

To set up the infrastructure, run the workflow, and verify the deployment, simply run:

```bash
make all
```

This single command performs the following steps:
1.  **`cluster`**: Creates a local Kind cluster (`argo-cluster`).
2.  **`argo`**: Installs Argo Workflows (Controller & UI) in the `argo` namespace.
3.  **`infra`**: Sets up the PVC and permissions.
4.  **`submit`**: Submits the Training & Serving workflow to Argo.
5.  **`verify`**: Waits for the deployment to be ready and tests the API endpoints.

## 🕹️ Manual Commands

You can also run steps individually:

- **Setup Cluster**: `make cluster`
- **Install Argo**: `make argo`
- **Setup Infra**: `make infra`
- **Submit Workflow**: `make submit`
- **Verify Deployment**: `make verify`
- **Clean Up**: `make clean` (Deletes the cluster)
- **Uninstall Tools**: `make uninstall-tools` (Removes downloaded binaries)

## 🔍 Verification

The `make verify` command performs an in-cluster check:
1.  Waits for the `model-serving` deployment to be `Available`.
2.  Launches a temporary pod to `curl` the internal service.
3.  Checks:
    - `GET /health`: Returns `{"status": "ok", ...}`
    - `POST /predict`: Returns a prediction for dummy features.

## 📊 Argo UI

You can access the Argo Workflows UI to visualize the DAG:

1.  Forward the Argo Server port:
    ```bash
    kubectl -n argo port-forward deployment/argo-server 2746:2746
    ```
2.  Open your browser at [https://localhost:2746](https://localhost:2746).
3.  Click "Workflows" to see the execution graph.

## 📝 Notes

- **Artifacts**: The trained model is stored in a 1Gi PVC (`model-pvc`) mounted at `/mnt/data`.
- **Git Artifacts**: The workflow fetches the latest scripts directly from this GitHub repository. Ensure your changes are pushed to `main` for them to be picked up by the workflow.