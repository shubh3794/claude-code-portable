---
name: cuda
description: CUDA kernel, GPU memory and multi-GPU (NCCL) practices. Use when writing or debugging .cu/.cuh code, custom kernels, GPU OOMs, or NCCL/multi-GPU issues.
---

# CUDA

## Correctness
- Check every runtime/driver call: wrap in a `CUDA_CHECK(...)` macro; after kernel launches check `cudaGetLastError()`, and in debug builds `cudaDeviceSynchronize()` too.
- Bounds-check every thread index (`if (i >= n) return;`); grid-stride loops for arbitrary sizes.
- `__syncthreads()` must be reached by all threads in the block — never inside divergent branches.
- Be explicit about streams; default-stream use silently serialises work. Use events for cross-stream ordering, not `cudaDeviceSynchronize()`.
- Pinned host memory (`cudaMallocHost`) for async copies; async copies from pageable memory are synchronous.

## Performance (measure first)
- Coalesced global access (consecutive threads → consecutive addresses); shared memory for reuse, padded to avoid bank conflicts.
- Block size a multiple of 32; check occupancy against register/shared-memory use.
- Profile with `nsys profile` (timeline) and `ncu` (per-kernel) before optimising.

## Debugging
```bash
compute-sanitizer --tool memcheck ./app     # also: racecheck, synccheck, initcheck
CUDA_LAUNCH_BLOCKING=1 ./app                # make errors surface at the faulting launch
nvidia-smi --query-gpu=index,memory.used,utilization.gpu --format=csv
NCCL_DEBUG=INFO NCCL_DEBUG_SUBSYS=INIT,NET ./app   # NCCL hangs/topology
```
- OOM: account for weights + gradients + optimizer state + activations + allocator fragmentation; in PyTorch check `torch.cuda.memory_summary()`.
- NCCL hangs: almost always mismatched collectives across ranks or a dead rank; set `NCCL_ASYNC_ERROR_HANDLING=1` / timeouts so they fail instead of hanging.
- Match CUDA toolkit, driver and framework versions (`nvcc --version`, `nvidia-smi`) before debugging anything else.
