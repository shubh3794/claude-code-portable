# Skill From Chat — Capture Current Conversation as a Skill

Analyze the conversation history in this session and extract a reusable skill from it.

## Process

### Step 1: Mine the Conversation
Look through our conversation and identify:
- **Actions taken**: What tools were used? What commands were run?
- **Decision points**: Where did I make choices or provide direction?
- **Corrections**: Where did I correct you or refine the approach?
- **Inputs**: What did I provide? What varied vs. what was constant?
- **Outputs**: What was the final deliverable?

### Step 2: Extract the Pattern
Separate into:
- **Fixed steps** (same every time) → these become skill instructions
- **Variable inputs** (change per invocation) → these become parameters
- **Validation criteria** (how I judged success) → these become the verification step
- **Corrections/lessons** (mistakes made) → these become edge cases + CLAUDE.md entries

### Step 3: Draft the Skill
Generate a complete skill with:
- SKILL.md (< 500 lines) with aggressive trigger descriptions
- scripts/ for any deterministic automation
- references/ for domain context docs
- 2-3 test cases in evals/evals.json

### Step 4: Present for Review
Show me:
1. The proposed skill name and trigger phrases
2. A summary of what it captures
3. The full SKILL.md content
4. Any scripts generated
5. Where to install it

Ask if I want to:
- Modify anything
- Add edge cases
- Adjust trigger sensitivity
- Generate more test cases

## Output Location
Save the generated skill to: `/home/claude/generated-skills/<skill-name>/`
Then show me how to install it:
```bash
cp -r /home/claude/generated-skills/<skill-name> ~/.claude/skills/
```

## Quality Checks
- Trigger description includes 5+ realistic user phrases
- Instructions are imperative, not explanatory
- Scripts are idempotent and safe to re-run
- No hardcoded secrets or environment-specific paths
- Source conversation is noted in a comment header
