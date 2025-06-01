# APT Archive

```
apt-archive/
├── .github/
│   └── workflows/
│       └── build.yml
├── scripts/
│   ├── wrap-to-deb.sh
│   ├── fetch-latest-version.sh
│   ├── build-repo.sh
│   ├── load-gpg-profile.sh
│   └── dev-container.sh
├── specs/
│   └── foobar.yml
├── pool/
│   └── foobar/   # debs are generated here
├── dists/        # signed repo metadata is generated here
├── README.md
```

```.env
GPG_KEY_ID=*****
GPG_PRIVATE_KEY=*****
```

```sh
docker compose run --build --rm --remove-orphans build
```

## TODO

- [ ] Generate dynamically the specs
