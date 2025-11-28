# Gluten Dev Container

With this dev container, you can:
* Build gluten from source
* Debugging with VS Code or any IDE with ssh support
* Develop unit tests with test containers

## Prerequisites

* Docker or Podman must be installed and running.

## Quick start

This environment can be run on both Linux and macOS.

Run the following command to clone the `gluten-dev` repository into your local `gluten` directory, start the dev container and enter the container shell.

```sh
# Inside your local gluten directory
git clone https://github.com/unidevel/gluten-dev.git

# Start the dev container and enter container shell
cd gluten-dev
make
```

## Dev with dev container(VSCode)

1. Install [Remote Development](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack) extension.
2. Install Microsoft [Extension Pack for Java](https://marketplace.visualstudio.com/items?itemName=vscjava.vscode-java-pack) and [C/C++ Extension Pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools-extension-pack) in the container.
3. Open `Remote Explorer` panel, switch to `Dev Containers` from the drop down widget on the top.

## Dev with ssh

VSCodium based IDEs cannot use the Remote Development extension. If your IDE supports remote ssh extension, you can try this:

1. Make sure you have generated ssh keys and updated the `authorized_keys` file in your local machine.
2. Use `make start` to start the container. This will copy your SSH keys from `~/.ssh/authorized_keys` to the `root/.ssh` directory inside `gluten-dev`.
3. Add the following entry to your local `~/.ssh/config` file:
```
Host gluten-dev
  HostName localhost
  Port 2222
  User root
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
```
4. Test the ssh connection with `ssh gluten-dev`.
5. Connect to the `gluten-dev` SSH server using your IDE.

## Keep your data

By default, the `root` directory in this repo will be mounted to `/root` in the container. Use this `root` directory to share your data between your local machine and the container.

By default, the `.ccache`, `.m2`, and `.cache` directories under `/root` directory are symbolic links to the image's `/opt/cache` directories. These symbolic links will disappear when the container is shut down. To preserve your cache data between container restarts, you need to replace these symbolic links with local directories in the mounted `/root` directory.

Run the following command in the shell of dev container:

```sh
use-local-cache
```

This script replaces the symbolic links with actual directories in your local `/root` folder, copying the cache data from `/opt/cache`. Since the `root` directory is mounted into the container, these cache files will be preserved even when the container is removed, significantly improving build performance on subsequent runs.
