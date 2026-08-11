# Langfuse in Compass Codex

Compass includes the official Langfuse Agent Skill and the public Langfuse
Docs MCP. Together they give Compass current product guidance and a
CLI-driven workflow for Langfuse project data without granting project access
by default.

## The three Langfuse surfaces

| Surface | Included by Compass | Authentication | Purpose |
| --- | --- | --- | --- |
| Agent Skill | Yes | Project keys only when accessing project data | Workflow guidance for tracing, prompts, datasets, evaluations, migrations, error analysis, and CI/CD gates; uses `langfuse-cli` for the REST API. |
| Docs MCP | Yes | None | Live semantic search and exact-page retrieval from current Langfuse documentation. |
| Project MCP | No; opt in per Codex installation | Project-scoped Basic Auth | Direct MCP tools for Langfuse project data, including read, write, and delete operations. |

Langfuse recommends the Agent Skill over the authenticated MCP when an agent
can install CLI tools and run shell commands. Compass follows that default and
keeps the privileged project MCP separate.

## Agent Skill setup

The skill is installed with Compass. Before asking it to read or change a
Langfuse project, set project-scoped credentials in the shell that launches
Codex:

```bash
export LANGFUSE_PUBLIC_KEY=pk-lf-...
export LANGFUSE_SECRET_KEY=sk-lf-...
export LANGFUSE_BASE_URL=https://cloud.langfuse.com
export LANGFUSE_HOST="$LANGFUSE_BASE_URL"
```

Use the base URL for the project's region or self-hosted deployment. Do not
paste keys into a prompt or commit them to the repository. The skill runs the
CLI through `npx`, so Node.js and package-registry access must be available.

## Bundled Docs MCP

The plugin registers `langfuse-docs` at
`https://langfuse.com/api/mcp`. It uses Streamable HTTP and needs no
credentials. Read tools can run normally, while tools marked as writes require
approval. Start a new Codex thread after installing or updating Compass,
then confirm it is active with:

```bash
codex mcp list
```

The Docs MCP currently provides:

- `searchLangfuseDocs` for semantic documentation search.
- `getLangfuseDocsPage` for the exact Markdown of a documentation page.
- `getLangfuseOverview` for the machine-readable documentation index.
- `submitFeedback` for explicit, user-approved documentation feedback.

Preview and approve the exact `submitFeedback` payload. Never include API
keys, project records, trace payloads, or other confidential data.

## Optional project MCP setup

Use this only when direct MCP tools are preferable to the bundled skill and
CLI. Create or copy a project API key pair in Langfuse, then expose an
authorization value to the shell that launches Codex:

```bash
export LANGFUSE_MCP_AUTHORIZATION="Basic $(printf '%s' "$LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY" | base64 | tr -d '\n')"
```

Add the server to `~/.codex/config.toml`. The environment-backed header keeps
the reversible Basic token out of the config file:

```toml
[mcp_servers.langfuse]
url = "https://cloud.langfuse.com/api/public/mcp"
env_http_headers = { "Authorization" = "LANGFUSE_MCP_AUTHORIZATION" }
default_tools_approval_mode = "writes"
```

Choose the matching endpoint:

| Deployment | URL |
| --- | --- |
| Cloud EU | `https://cloud.langfuse.com/api/public/mcp` |
| Cloud US | `https://us.cloud.langfuse.com/api/public/mcp` |
| Cloud Japan | `https://jp.cloud.langfuse.com/api/public/mcp` |
| HIPAA US | `https://hipaa.cloud.langfuse.com/api/public/mcp` |
| Self-hosted | `https://your-domain.com/api/public/mcp` |
| Local development | `http://localhost:3000/api/public/mcp` |

Restart Codex, run `codex mcp list`, and ask Compass to list the project's
prompts as a smoke test. It should call `listPrompts`.

### Restrict project tools

The project MCP exposes read and write tools by default, including destructive
operations. `default_tools_approval_mode = "writes"` prompts before tools not
marked read-only. For a strict read-only setup, review the current canonical
tool reference and copy only the desired read operations into the server's
`enabled_tools` allowlist. Tool names and schemas are dynamic, so do not rely
on a stale copied list.

The project MCP covers prompts; observations such as generations, spans,
events, agent steps, and tool calls; annotation queues; comments; datasets and
experiments; scores and score configurations; metrics; models and media;
evaluators and evaluation rules; dashboards and widgets; monitors; health;
and feedback. Some observation, experiment, and monitor tools require
Langfuse v4.

For self-hosted production, use HTTPS. Reverse proxies must preserve the
public `Host` header, or `LANGFUSE_MCP_ALLOWED_HOSTS` must include the exact
additional hostname or origin.

## Sources

- [Langfuse Agent Skill documentation](https://langfuse.com/docs/api-and-data-platform/features/agent-skill)
- [Official Langfuse skill repository](https://github.com/langfuse/skills)
- [Langfuse project MCP setup](https://langfuse.com/docs/api-and-data-platform/features/mcp-server)
- [Langfuse Docs MCP setup](https://langfuse.com/docs/docs-mcp)
- [Canonical Langfuse MCP tool reference](https://mcp.reference.langfuse.com/)
- [Official Codex MCP configuration](https://developers.openai.com/codex/mcp/)
