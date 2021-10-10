# bashborg

Create borg backups configurable via a ssh-like config.

## Features

- A single config for all your backups
- Just a bash script
- Still easy to configure for just a single backup
- familiar SSH config syntax

## Configuration

The config file is located at `~/.config/borg/backups` by default.

### Examples

```bash
# Sets a global default compression
Compression auto,zstd,12

# The name is just used for logging
Backup local
    Repo ~/backup
    Passphrase hunter2

Backup remote
    Repo backup:~/backup
    # Gets the passphrase via pass
    PassCommand "pass backups/remote | head -n1"
```

```bash
# Setting the repo globally allows configuring a single backup
Repo backup:~/backup
```

### Options

#### `Repo`

Repository to backup to.

#### `Path`

**Default**: `~`

Path to backup.

#### `Compression`

Comprssion to use.
See `borg help compression` for more information.

#### `Archive`

**Default**: `$(date -I)` (The current date in ISO format)

Name of the archive to create.

#### `IgnoreFile`

**Default**: `.borgignore`

File passed to borg via `--exclude-from`.
If it's a relative path (not starting with `/`), it gets appended to `Path`.

#### `Passphrase`

Passphrase passed to borg.

#### `PassCommand`

When set, the output of this command will be used as the passphrase.

## How it works

Each option is a bash function, which sets the option to the first argument it receives.
That means, if your option includes spaces, you need to quote it.
