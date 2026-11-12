#!/usr/bin/env python3
import argparse
import csv
import json
from pathlib import Path


def median(values):
    values = sorted(values)
    n = len(values)
    m = n // 2
    return values[m] if n % 2 else (values[m - 1] + values[m]) / 2


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    rows = []
    for file_path in sorted(Path(args.input).glob("*.json")):
        with file_path.open("r", encoding="utf-8") as f:
            data = json.load(f)

        runs = data["runs"]
        rows.append({
            "config": data["config"],
            "instance_type": data["instance_type"],
            "pricing": data["pricing"],
            "precision": data["precision"],
            "concurrency": data["concurrency"],
            "ttft_ms": round(median([r["time_to_first_token_ms"] for r in runs]), 2),
            "per_token_ms": round(median([r["per_token_latency_ms"] for r in runs]), 3),
            "tokens_per_second": round(median([r["tokens_per_second"] for r in runs]), 2),
            "requests_per_second": round(median([r["requests_per_second"] for r in runs]), 4),
            "gpu_utilization_pct": round(median([r["gpu_utilization_pct"] for r in runs]), 2),
            "cost_per_1m_tokens_usd": data["cost_per_1m_tokens_usd"],
            "vllm_version": data["vllm_version"],
            "cuda_driver": data["cuda_driver"],
            "karpenter_version": data["karpenter_version"],
            "region": data["region"],
            "price_per_hour_usd": data["price_per_hour_usd"],
        })

    rows.sort(key=lambda r: (r["config"], int(r["concurrency"])))
    if not rows:
        raise SystemExit(f"no benchmark JSON files found in {args.input}")

    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    with open(args.output, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    main()
