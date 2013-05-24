# ProfileProbe

This is a program that keeps track of running processes, their stats, and their
open network connections. Processes can be filtered using regexes on the process
cmdline property. The regexes must be stored in a config file.

The `lib/proc_fs/` library may be used as a standalone library.

## Running ProfileProbe

The main executable is `bin/ProfileProbe`. Running this executable without any
environment variables set will start outputting JSON to the screen. This is
probably way too much data for anyone, so one can write a config file which
specifies regexes to filter by process command line strings.

Assuming you've cloned ProfileProbe into your `/vagrant/src/` directory, run:

    CONF=/vagrant/src/ProfileProbe/config/example.json /vagrant/src/ProfileProbe/bin/ProfileProbe

to load the example json config file.

## Output Structure

Each sample in time is outputted as a JSON data structure. These are each
separated by `\n\r\n\r` values.

The data is stored in a hierarchy. Each section of the output is a diff of this
hierarchy. The hierachy roughly looks like:

    Time Sample
      `- Processes
          |- Process Values
          `- Sockets
               ` Socket Values

Since the diffing operation is not commutative, diff operations create a new
structure containing right-hand side only, left-hand side only, and then actual
difference only (just what changed) values.

Internally, each state is represented as a hash in the tree. This is akin to how
a Merkle tree works, but with a set of values instead of a block of data. This is
used for fast comparisons of states. It can also be used to contruct a chain of
states or detecting if a repeat state ever occurs.