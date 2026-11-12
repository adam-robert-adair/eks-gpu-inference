#!/usr/bin/env python3
import argparse
import csv


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    with open(args.input, "r", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))

    lines = [
        "# Benchmark Summary",
        "",
        "| Config | Instance | Pricing | Precision | Concurrency | TTFT (ms) | Per-token (ms) | Tokens/s | RPS | GPU util (%) | Cost / 1M tokens ($) |",
        "|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|",
    ]

    for row in rows:
        lines.append(
            f"| {row['config']} | {row['instance_type']} | {row['pricing']} | {row['precision']} | {row['concurrency']} | {row['ttft_ms']} | {row['per_token_ms']} | {row['tokens_per_second']} | {row['requests_per_second']} | {row['gpu_utilization_pct']} | {row['cost_per_1m_tokens_usd']} |"
        )

    with open(args.output, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
