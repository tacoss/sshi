# SSHi

Do you have to upload or download files, execute commands remotely?

- `sshi scp local.txt @remote:/path/to`
- `sshi @remote du -h /tmp`
- `sshi @my-site`

Install `sshi` globally or within your project:

```
$ npm i -g sshi # or `npm i sshi --save-dev`
```

## How it works?

It stores your input in the `~/.sshiconf` file, each line is a record with name/endpoint separated by white-space, e.g.

```text
admin root@remote.com -p 22022 -L 1025:localhost:1025
my-site deploy@my-website.com
```

Just type `sshi @admin` to get connected, any additional arguments are sent as command through the SSH connection.

- To add new endpoints `sshi save name user@host [...]`
- To remove added endpoints `sshi del name`
- To list all registered endpoints `sshi ls`

When the first argument is not an `@endpoint` placeholder, then command substitution is performed and executed, e.g.

```bash
$ sshi echo Your connection is: @my-site
# Your connection is: deploy@my-website.com
```

> Additional arguments after `user@host` are always saved, and also given to expanded commands.
