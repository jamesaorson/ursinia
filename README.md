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
$ ssh ursinia
$ cd ./github.com/jamesaorson/ursinia

$ git pull
Already up to date.

$ make deploy
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
```