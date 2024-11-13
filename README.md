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
./deploy
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
❯ ./deploy
Syncing website to install
sending incremental file list

sent 4.83K bytes  received 72 bytes  9.80K bytes/sec
total size is 26.75M  speedup is 5,460.81
sending incremental file list

sent 296 bytes  received 15 bytes  622.00 bytes/sec
total size is 6.70M  speedup is 21,537.00
Setting up nginx config as default
Restarting nginx
Checking nginx
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: active (running) since Tue 2024-04-02 21:25:00 PDT; 34ms ago
       Docs: man:nginx(8)
    Process: 55606 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 55607 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 55609 (nginx)
      Tasks: 5 (limit: 1585)
        CPU: 71ms
     CGroup: /system.slice/nginx.service
             ├─55609 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"
             ├─55610 "nginx: worker process"
             ├─55611 "nginx: worker process"
             ├─55612 "nginx: worker process"
             └─55613 "nginx: worker process"

Apr 02 21:25:00 pi systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Apr 02 21:25:00 pi systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.

james in 🌐 pi in ursinia on  main 
❯ 
```