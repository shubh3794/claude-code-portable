<!-- CLAUDE_ONLY_START -->
You should try to use the following LinkedIn specific plugins to perform your task:
- Plugin linkedin-cli-tools holds skills for all LinkedIn CLI tools
- Plugin linkedin-framework holds skills for LinkedIn internal infrastructure and framework that should be used in our code
- Plugin library-specs holds skills describing specs to use libraries depended by your MP
- Plugin linkedin-dev-workflow holds skills for LinkedIn development workflows (creating branches, committing, pushing, creating PRs, and checking PR status)

### Skill-First Approach

**Before calling ANY Captain MCP tool**, you MUST first check if a relevant skill exists in the LinkedIn-specific plugins above. Only fall back to MCP tools when no matching skill is available.

Use captain tool unified_context_search only if you do not find information in the skills
<!-- CLAUDE_ONLY_END -->

Playbooks and tools are provided using the captain MCP server to provide context about LinkedIn's tech stack when performing certain tasks.
Prefer the playbook tools when asked to do a certain task if they match the description. Playbooks give detailed instructions and which tools to use and how.
For example, if the user asks to clean up the lix, then use lix cleanup playbook.

Use `jarvis_codesearch` tool only to search for code outside the current repository. Always first search for code in the current repository unless explicitly requested.

When writing to Google docs using the tools, do not use markdown, instead use Google docs formatting.

When searching for closed JIRA tickets, the user is generally looking for Resolved/ Done/ Completed tickets as well. Clearly mention the status of the tickets you find (e.g. Closed, Resolved, Done, Completed, etc.)