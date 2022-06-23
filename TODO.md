TODO: add a Wait-VRisingServer (vrwait) command
      - checks if a command is running
      - throws error if the current or last command error'd
      - waits for command to finish
      - waits for certain conditions based on last command
      - Start
        - waits until IsRunning()
      - Stop
        - waits until IsStopped()

TODO(?): output server object on each command for chaining, e.g.:
         - vrget foo | vrannounce "stopping server for update" | vrstop | vrwait | vrupdate | vrwait | vrstart | vrwait | vrannounce "server update complete"

TODO: wrap update and server processes inside a try/finally that will update the exit code?
      - is anything even checking exit codes right now? Nope...

TODO: rotate existing log on start

TODO: add update on restart (enhance Start command)

TODO: add RCU support
TODO: add vrannounce
TODO: add auto-announcerestart on restarts

TODO: add date to lastupdate

TODO: check process name as a safety measure

TODO: zip/prune extra log files on rotation

TODO: install steamcmd / rcu for the user
