podman build --no-cache --rm --file Containerfile -t mariadb:demo .
podman run --interactive --tty --publish 3306:3306 mariadb:demo
