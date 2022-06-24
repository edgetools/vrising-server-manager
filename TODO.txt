TODO: wrap update and server processes inside a try/finally that will update the exit code?
      - is anything even checking exit codes right now? Nope...
      - THIS DIDN'T WORK... sending WM close stops the foreground process (VRisingServer) but then powershell immediately dies, so to address that:

TODO^: overhaul DoCommands to use process monitors /  watchers
       - rather than commands, launch a process monitor
       - runs a loop, sleeps every second, then checks the command queue
       - if the command queue goes empty and the server is stopped, stop the process monitor
       - if the process monitor isn't started when a command is issued, start the process monitor
       - if a command is in the queue (file), pulls it off the top, processes it, then writes the removal once it finishes
       - kill commands for update/start will still directly target the underlying process
       - stop commands will issue a command in the commandqueue
       - can also stop the current command itself by killing the process id or setting kill = true?
       - every loop, readproperties:
         - CommandQueue
         - KeepCommandRunning

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

TODO: rotate existing log on start

TODO: add update on restart (enhance Start command)

TODO: add RCU support
TODO: add vrannounce
TODO: add auto-announcerestart on restarts

TODO: add date to lastupdate

TODO: check process name as a safety measure

TODO: zip/prune extra log files on rotation

TODO: install steamcmd / rcu for the user
