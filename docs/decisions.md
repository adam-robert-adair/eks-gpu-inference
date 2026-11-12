# Decisions and trade-offs

- **Karpenter** provides just-in-time GPU node provisioning and consolidation when workloads are idle.
- **NVIDIA device plugin** is installed via Helm so GPU resources are discoverable (`nvidia.com/gpu`) on accelerated EKS worker nodes.
- **vLLM** was selected for its OpenAI-compatible serving API and benchmark-friendly behavior.
- **KEDA** scales vLLM from zero based on queue depth from Prometheus (`vllm:num_requests_waiting`) instead of CPU-only scaling.
- **Spot + on-demand fallback** is controlled by NodePool capacity-type requirements.
