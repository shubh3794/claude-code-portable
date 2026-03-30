# Skill Watch — Proactive Pattern Scanner

Scan my recent workflow patterns and propose contextual skills I should create.

## What to analyze

1. **Shell history** (`~/.zsh_history` or `~/.bash_history`, last 200 entries):
   - Find command sequences repeated 2+ times
   - Group by tool (kubectl, docker, git, python, etc.)
   - Identify multi-step workflows (3+ commands in sequence)

2. **Git history** (`git log --oneline --since="2 weeks ago"`):
   - Commit message patterns (fix:, feat:, refactor:, etc.)
   - Files modified together frequently
   - Branches created/merged patterns

3. **CLAUDE.md lessons** (scan all CLAUDE.md files in project + home):
   - Corrections that imply a multi-step process
   - "Always" / "Never" rules that could be automated
   - Domain-specific conventions

4. **Recent file modifications** (last 7 days):
   - File types created/modified in clusters
   - Test files alongside implementation files
   - Config files updated in patterns

## Output format

Present findings as a ranked proposal list:

```
🔍 Detected Workflow Patterns:

1. [HIGH VALUE] <Pattern Name>
   Pattern: <command1> → <command2> → <command3>
   Frequency: Seen N times in last 2 weeks
   Est. time savings: ~X min per occurrence
   Skill idea: <one-line description>

2. [MEDIUM VALUE] ...
```

Then ask me which ones to turn into skills. For each selected pattern,
generate a complete skill using the skill-builder-agent skill.

## Important

- Don't just list commands — identify the INTENT behind the sequence
- Group related commands into coherent workflows
- Prioritize by (frequency × time_per_occurrence)
- Consider my domain context when interpreting patterns
- Be specific about trigger phrases that would activate each proposed skill
