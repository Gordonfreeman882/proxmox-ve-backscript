proxmox-ve-backscript - !Pre-Alpha!
  - Do not use for production! -

Features:
- downloads your backupfiles from the proxmox-ve server over to your system.
- compares remote and local files via hashes do prevent unnecessary downloads
- only german language available

Requirements:
- sshpass
- tested on debian and ubuntu systems

Future updates:
- language detection
- make disk space test working
- optional mail notification
- reduce systemload while creating hashsum
