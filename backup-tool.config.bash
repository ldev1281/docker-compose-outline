#!/bin/bash

# List of files and directories to backup (relative to PROJECT_ROOT)
TO_BACKUP=(
    ".env"
    "vol"
)

# GPG recipient fingerprint (optional; leave empty "" to disable encryption)
GPG_FINGERPRINT="8711DC604014FF89EE24ABBB6D4C8C1B23638B65"