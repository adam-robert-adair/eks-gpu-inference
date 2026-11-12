SHELL := /bin/bash
TF_DIR := terraform
MODEL_ENDPOINT ?= http://vllm.vllm.svc.cluster.local:8000/v1
BENCH_CONFIGS := benchmarks/configs/g5xlarge-spot-fp16.yaml benchmarks/configs/g6xlarge-ondemand-awq.yaml

.PHONY: up bench down validate smoke

up:
	terraform -chdir=$(TF_DIR) init
	terraform -chdir=$(TF_DIR) apply -auto-approve
	kubectl apply -f k8s/vllm/deployment.yaml
	kubectl apply -f k8s/vllm/autoscaling.yaml
	kubectl apply -f k8s/monitoring/servicemonitor.yaml

smoke:
	kubectl apply -f k8s/vllm/gpu-smoke-test.yaml
	kubectl wait --for=condition=Ready pod/gpu-smoke-test -n vllm --timeout=600s || true
	kubectl logs pod/gpu-smoke-test -n vllm
	kubectl delete -f k8s/vllm/gpu-smoke-test.yaml --ignore-not-found

bench:
	rm -f benchmarks/results/raw/*.json
	for cfg in $(BENCH_CONFIGS); do \
		python3 benchmarks/scripts/run_bench.py --config $$cfg --endpoint $(MODEL_ENDPOINT); \
	done
	python3 benchmarks/scripts/collect.py --input benchmarks/results/raw --output benchmarks/results/results.csv
	python3 benchmarks/scripts/summarize.py --input benchmarks/results/results.csv --output benchmarks/results/results.md


down:
	kubectl delete -f k8s/monitoring/servicemonitor.yaml --ignore-not-found
	kubectl delete -f k8s/vllm/autoscaling.yaml --ignore-not-found
	kubectl delete -f k8s/vllm/deployment.yaml --ignore-not-found
	terraform -chdir=$(TF_DIR) destroy -auto-approve

validate:
	terraform -chdir=$(TF_DIR) fmt -check -recursive
	terraform -chdir=$(TF_DIR) init -backend=false
	terraform -chdir=$(TF_DIR) validate
	python3 -m py_compile benchmarks/scripts/*.py
