podman build --no-cache --rm -f Containerfile -t apachephp:demo .
podman run --interactive --tty -p 8080:80 apachephp:demo
echo "browse http://localhost:8080/info.php"
