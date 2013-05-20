#ProfileProbe

This is a program that keeps track of running processes, their stats, and their
open network connections. Processes can be filtered using regexes on the process
cmdline property. The regexes must be stored in a config file.

The `lib/proc_fs/` library may be used as a standalone library.