# Ursinia

## Important Links

- [Website](https://ursinia.net)
- [Source Repository](https://git.sr.ht/~jamesaorson/ursinia)

## Instructions

To deploy the website with changes

```shell
ssh pi
# Once logged in...
cd ./github.com/jamesaorson/ursinia
git pull
make deploy # or ./scripts/deploy
exit
```

Here is a full example with output:

```shell
tashasorson@Jamess-MacBook-Pro ursinia % ssh pi
james@10.0.0.217's password: 
Linux pi 6.1.0-rpi8-rpi-v8 #1 SMP PREEMPT Debian 1:6.1.73-1+rpt1 (2024-01-25) aarch64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Tue Apr  2 21:23:11 2024 from 10.0.0.4

james in 🌐 pi in ~ 
❯ cd ./github.com/jamesaorson/ursinia

james in 🌐 pi in ursinia on  main 
❯ git pull
Already up to date.

james in 🌐 pi in ursinia on  main 
❯ make deploy
Syncing website to install
sending incremental file list

sent 4.94K bytes  received 76 bytes  10.03K bytes/sec
total size is 64.63M  speedup is 12,890.22
sending incremental file list

sent 336 bytes  received 15 bytes  702.00 bytes/sec
total size is 9.60M  speedup is 27,359.06
Setting up nginx config as default
Restarting nginx
Checking nginx
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: active (running) since Thu 2024-11-14 10:04:16 PST; 36ms ago
       Docs: man:nginx(8)
    Process: 164229 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 164230 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 164231 (nginx)
      Tasks: 5 (limit: 1582)
        CPU: 67ms
     CGroup: /system.slice/nginx.service
             ├─164231 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"
             ├─164232 "nginx: worker process"
             ├─164233 "nginx: worker process"
             ├─164234 "nginx: worker process"
             └─164235 "nginx: worker process"

Nov 14 10:04:16 pi systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Nov 14 10:04:16 pi systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.

james in 🌐 pi in ursinia on  main 
❯ 
```