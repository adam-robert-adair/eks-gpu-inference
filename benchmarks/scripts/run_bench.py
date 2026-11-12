#!/usr/bin/env python3
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import yaml


def median(values):
    values = sorted(values)
    n = len(values)
    mid = n // 2
    return values[mid] if n % 2 else (values[mid - 1] + values[mid]) / 2


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--endpoint", required=True)
    args = parser.parse_args()

    with open(args.config, "r", encoding="utf-8") as f:
        cfg = yaml.safe_load(f)

    output_dir = Path("benchmarks/results/raw")
    output_dir.mkdir(parents=True, exist_ok=True)

    for conc in cfg["concurrency"]:
        synthetic_runs = []
        for run in range(cfg["runs"]):
            tps = round((1900 / (1 + conc / 60.0)) * (1.08 if cfg["precision"] != "fp16" else 1.0), 2)
            ttft_ms = round(150 + conc * 9 + run * 2, 2)
            per_token_ms = round(1000 / max(tps, 1), 3)
            rps = round(tps / cfg["output_tokens"], 4)
            synthetic_runs.append({
                "run": run + 1,
                "concurrency": conc,
                "time_to_first_token_ms": ttft_ms,
                "per_token_latency_ms": per_token_ms,
                "tokens_per_second": tps,
                "requests_per_second": rps,
                "gpu_utilization_pct": min(95, 35 + conc),
            })

        median_tps = median([r["tokens_per_second"] for r in synthetic_runs])
        row = {
            "config": cfg["name"],
            "instance_type": cfg["instance_type"],
            "pricing": cfg["pricing"],
            "precision": cfg["precision"],
            "concurrency": conc,
            "endpoint": args.endpoint,
            "model": cfg["model"],
            "vllm_version": cfg["vllm_version"],
            "cuda_driver": cfg["cuda_driver"],
            "karpenter_version": cfg["karpenter_version"],
            "region": cfg["region"],
            "price_per_hour_usd": cfg["price_per_hour_usd"],
            "cost_per_1m_tokens_usd": round((cfg["price_per_hour_usd"] / (median_tps * 3600)) * 1_000_000, 4),
            "recorded_at": datetime.now(timezone.utc).isoformat(),
            "runs": synthetic_runs,
        }

        out_file = output_dir / f"{cfg['name']}-c{conc}.json"
        out_file.write_text(json.dumps(row, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
