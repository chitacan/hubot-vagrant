# hubot-vagrant

A Vagrant helper for Hubot.

## Installation

In hubot project repo, run:

`npm install hubot-vagrant --save`

Then add **hubot-vagrant** to your `external-scripts.json`:

```json
["hubot-vagrant"]
```

## Commands

```
hubot vagrant create  <name> <repo>  - Downloads & creates Vagrant machine from given Vagrantfile url(github, gist repo only).
hubot vagrant destroy <name> - Deletes machine.
hubot vagrant format  <name> <json> - Formats Vagrantfile with string-template module.
hubot vagrant list           - Prints current virtual machine list.
hubot vagrant halt    <name> - Stops machine.
hubot vagrant reload  <name> - Restarts machine.
hubot vagrant show    <name> - Shows Vagrantfile.
hubot vagrant status  <name> - Prints machine status.
hubot vagrant suspend <name> - Suspends machine.
hubot vagrant up      <name> - Starts up machine.
hubot vagrant update  <name> - Updates machine's git repo.
```
