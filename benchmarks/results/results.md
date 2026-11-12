# Benchmark Summary

| Config | Instance | Pricing | Precision | Concurrency | TTFT (ms) | Per-token (ms) | Tokens/s | RPS | GPU util (%) | Cost / 1M tokens ($) |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| g5xlarge-spot-fp16 | g5.xlarge | spot | fp16 | 1 | 161 | 0.535 | 1868.85 | 7.3002 | 36 | 0.0782 |
| g5xlarge-spot-fp16 | g5.xlarge | spot | fp16 | 4 | 188 | 0.561 | 1781.25 | 6.958 | 39 | 0.082 |
| g5xlarge-spot-fp16 | g5.xlarge | spot | fp16 | 16 | 296 | 0.667 | 1500.0 | 5.8594 | 51 | 0.0974 |
| g5xlarge-spot-fp16 | g5.xlarge | spot | fp16 | 64 | 728 | 1.088 | 919.35 | 3.5912 | 95 | 0.1589 |
| g6xlarge-ondemand-awq | g6.xlarge | on-demand | awq | 1 | 161 | 0.495 | 2018.36 | 7.8842 | 36 | 0.1208 |
| g6xlarge-ondemand-awq | g6.xlarge | on-demand | awq | 4 | 188 | 0.52 | 1923.75 | 7.5146 | 39 | 0.1268 |
| g6xlarge-ondemand-awq | g6.xlarge | on-demand | awq | 16 | 296 | 0.617 | 1620.0 | 6.3281 | 51 | 0.1505 |
| g6xlarge-ondemand-awq | g6.xlarge | on-demand | awq | 64 | 728 | 1.007 | 992.9 | 3.8785 | 95 | 0.2456 |
