# Skill For Domain — Domain-Specific Skill Generator

Generate skills tailored to a specific domain by reading project configs and conventions.

## Usage
`/skill-for <domain>`

Examples:
- `/skill-for k8s-gpu-scheduling`
- `/skill-for distributed-training`
- `/skill-for volcano-jobs`
- `/skill-for criu-checkpoint`
- `/skill-for api-design`

## Process

### Step 1: Domain Discovery
Based on the domain argument, scan the project for relevant files:

**Kubernetes / GPU Scheduling:**
- `*.yaml` manifests, Helm charts, kustomize overlays
- Volcano `Queue`, `PodGroup`, `Job` definitions
- GPU resource requests/limits patterns
- Monitoring configs (Prometheus rules, Grafana dashboards)

**Distributed Training:**
- Training scripts, config files
- Checkpoint/restart logic
- FSDP/DDP configuration
- NCCL environment variables

**General:**
- README.md, CONTRIBUTING.md
- CI/CD configs (.github/workflows, Jenkinsfile)
- Makefile, package.json scripts
- Docker/Compose files

### Step 2: Identify Skill Opportunities
For each domain, look for:
1. **Diagnostic workflows**: "Something is wrong with X" → investigate → fix
2. **Operational procedures**: Deploy, rollback, scale, migrate
3. **Investigation patterns**: Trace, profile, benchmark, compare
4. **Creation workflows**: New service, new job, new config

### Step 3: Generate Skills
For each identified opportunity, create a skill that:
- Reads the RIGHT files for context (reference files, not hardcoded knowledge)
- Runs the RIGHT commands for investigation
- Follows the project's ACTUAL conventions (from configs, not assumptions)
- Includes project-specific edge cases

### Step 4: Present Menu
Show the user all generated skill proposals and let them pick which to install.

## Domain Templates

### k8s-gpu-scheduling
Propose skills for:
- GPU job submission with Volcano best practices
- Pod failure diagnosis (OOM, GPU errors, scheduling failures)
- GPU utilization monitoring and alerting
- Preemption and priority configuration
- Node affinity and topology-aware scheduling

### distributed-training
Propose skills for:
- Training job checkpoint/restart workflow
- OOM debugging (optimizer state, all-gather buffers, activation memory)
- Multi-node training failure diagnosis
- NCCL debugging and performance tuning
- Scaling experiments (strong vs weak scaling)

### criu-checkpoint
Propose skills for:
- CRIU + cuda-checkpoint validation on target hardware
- Transparent checkpoint integration testing
- NCCL communicator state restoration debugging
- Checkpoint size optimization
- Preemption-triggered checkpoint workflow
