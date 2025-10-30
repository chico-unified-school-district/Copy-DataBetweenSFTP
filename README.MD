# Copy-DataBetweenSFTP

Purpose

- Scripts to copy data between SFTP servers (and/or local paths) as part of scheduled jobs or CI/CD pipelines.

Key points

- Lightweight PowerShell-based workflow.
- Configurable via parameter and task files.
- Intended to run manually, scheduled (Task Scheduler) or in CI (Jenkins).

Prerequisites

- Windows PowerShell (5.1+) or PowerShell Core.
- SFTP client support (WinSCP, OpenSSH sftp, or PowerShell modules).
- Network access and credentials for source and destination SFTP servers.
- Optional: Jenkins for automated runs.

Repository layout (important files)

- params.ps1 — parameter values (endpoints, credentials, paths).
- tasks.ps1 — task definitions (what to copy, scheduling metadata).
- jenkins.ps1 — Jenkins helper script (pipeline invocation).
- .gitignore — files to keep out of source control (already configured).

Configuration

1. params.ps1

   - Populate hostnames, ports, user names, and secure credential handling.
   - Keep secrets out of the repo; use secure vaults or Jenkins credentials where possible.

2. tasks.ps1
   - Define source/destination pairs and any include/exclude rules.
   - Configure retry policies, logging locations and retention.

Usage

- Manual run:

  - Open PowerShell in this folder.
  - Dot-source or run the main script (example):
    - .\tasks.ps1
    - Or: powershell -File .\tasks.ps1 -Environment "prod"

- Scheduled run:

  - Create a Task Scheduler job pointing to PowerShell with the script and required parameters.
  - Ensure the run-as account has necessary network and file permissions.

- Jenkins:
  - Use jenkins.ps1 or invoke PowerShell from a Jenkins pipeline.
  - Store credentials in Jenkins Credentials and inject them at runtime.

Examples

- Example: copy all CSVs from remote SFTP to anther remote SFTP
  - Configure a task in tasks.ps1 with SourceHost, SourcePath, DestinationPath and file mask `*.csv`.
  - Run the task and verify logs.

Logging & Monitoring

- Write logs to a configurable folder (set in params.ps1).
- Rotate logs or purge old files based on retention policy.

Security

- Never commit plaintext credentials.
- Prefer using secure stores (Windows Credential Manager, Vault, or Jenkins credentials).
- Limit access to the service account used for SFTP operations.

Troubleshooting

- Connection failures: verify host, port, firewall rules and credentials.
- Permission errors: confirm destination folder ACLs and account privileges.
- File not found: check paths and file masks; test with a single known file.

Contributing

- Fork, make changes, and submit a PR.
- Keep secrets and environment-specific data out of commits.

Contact / Maintainer

- Maintain scripts in this repository. For issues, open an issue in the repo or contact the script owner.

License

- Add license info here if applicable.
