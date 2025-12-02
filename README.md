# mlops_automation

## Infrastructure Automation

This repository contains the automation scripts to set up the infrastructure for the MLOps pipeline.

### Quick Start

We provide a `Makefile` to automate the process: creating the cluster, installing Argo, and setting up the artifact store (PVC).

Run the following command from the `mlops_automation` directory:

```bash
make all
```

This will:
1.  Check for and install `kind`, `kubectl`, and `argo` if missing.
2.  Create a local Kind cluster (`argo-cluster`).
3.  Install Argo Workflows (Controller & UI).
4.  Create a PersistentVolumeClaim (PVC) for model storage.

### Clean Up

To delete the cluster:

```bash
make clean
```

### Uninstall Tools

To remove the installed tools (`kind`, `kubectl`, `argo`):

```bash
make uninstall-tools
```