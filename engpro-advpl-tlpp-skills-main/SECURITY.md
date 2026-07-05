# Security Policy

## Philosophy

Agent Skills is a **managed, hardened** skill registry. Unlike open marketplaces where [over 13% of skills contain critical issues](https://github.com/snyk/agent-scan/blob/main/.github/reports/skills-report.pdf), every skill and every tool in this repository is designed with security as a first-class constraint — not an afterthought.

Security here means three things: protecting **your environment** (CLI defense-in-depth), protecting **your context window** (MCP progressive disclosure), and protecting **your trust** (supply chain integrity).

## Threat Model

We directly address the threats identified in the [Snyk 2026 Agent Threat Report](https://github.com/snyk/agent-scan/blob/main/.github/reports/skills-report.pdf):

| Threat                   | Public Marketplaces                                         | Agent Skills Guarantee                                                                                          |
| :----------------------- | :---------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------- |
| **Malicious Payloads**   | Obfuscated code, binaries, or "black box" instructions      | **100% Open Source**: No binaries, fully readable text/code. Every line is auditable.                           |
| **Credential Theft**     | Skills silently exfiltrating env vars to remote servers     | **Static Analysis**: CI/CD pipeline blocks skills with suspicious network calls or secret access.               |
| **Prompt Injection**     | Hidden instructions to hijack agent behavior ("jailbreaks") | **Human Curation**: Every prompt is manually code-reviewed by maintainers for safety boundaries.                |

## Reporting a Vulnerability

If you discover a security issue in any skill or reference file, **do not open a public issue**. Instead:

1. Send an email to the repository maintainers with the subject **[SECURITY] Brief description**.
2. Include: affected skill path, description of the issue, and steps to reproduce.
3. You will receive an acknowledgment within **48 hours** and a resolution timeline within **5 business days**.
