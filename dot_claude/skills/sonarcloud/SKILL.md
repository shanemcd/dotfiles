---
name: sonarcloud
description: Query SonarCloud for code quality issues, security hotspots, and PR status
---

# SonarCloud Skill

Use this skill when the user asks about SonarCloud issues, code quality, security hotspots, or wants to check the status of a PR on SonarCloud.

## Authentication

The SonarCloud token is stored in the system keychain:

```bash
# Retrieve token
secret-tool lookup service sonar

# Store token (interactive, prompts for value)
secret-tool store --label="SonarCloud Token" service sonar username <username>
```

## Querying Issues on a PR

```bash
SONAR_TOKEN=$(secret-tool lookup service sonar)

# Get all issues on a PR
curl -s -u "${SONAR_TOKEN}:" \
  "https://sonarcloud.io/api/issues/search?componentKeys=ansible_aap-dev&pullRequest=<PR_NUMBER>&statuses=OPEN,CONFIRMED&sinceLeakPeriod=true"

# Parse the response
curl -s -u "${SONAR_TOKEN}:" \
  "https://sonarcloud.io/api/issues/search?componentKeys=ansible_aap-dev&pullRequest=<PR_NUMBER>&statuses=OPEN,CONFIRMED&sinceLeakPeriod=true" \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(f'Total issues: {data[\"total\"]}')
for issue in data.get('issues', []):
    print(f'  [{issue.get(\"severity\")}] {issue.get(\"type\")} | {issue.get(\"component\")}:{issue.get(\"line\",\"?\")}')
    print(f'    {issue.get(\"message\")}')
    print()
"
```

## Querying Security Hotspots

```bash
curl -s -u "${SONAR_TOKEN}:" \
  "https://sonarcloud.io/api/hotspots/search?projectKey=ansible_aap-dev&pullRequest=<PR_NUMBER>&status=TO_REVIEW"
```

## API Reference

- Base URL: `https://sonarcloud.io/api`
- Auth: Basic auth with token as username, empty password (`-u "${TOKEN}:"`)
- Project key for aap-dev: `ansible_aap-dev`
- Web UI: `https://sonarcloud.io/summary/new_code?id=ansible_aap-dev&pullRequest=<PR_NUMBER>`
