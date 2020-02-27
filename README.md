# Elm blog

[![Build Status][travis-badge-dev]][travis-build]

A mini blog made using only [Elm 0.19.1][elm_0_19_1]!

Check out the demo at [dptole.ngrok.io/elm-blog/][demo].

This is meant to be a learning project in order to slowly shift from OP to FP, or at least learn more about it.

In my opinion Elm (FP) is way simpler than OP, more elegant and more flexible when combining different modules or using their singular features/functions while still strickly sticking to the architecture.

# Stats

Files      | Lines Of Code | Size   | Served via HTTP
---------- | ------------- | ------ | ---
Elm        | 17k+          | 416kb+ (frontend) | Compressed (brotli) 43kb
JavaScript | 4.6k+         | 114kb+ (backend) | N/A

All the CSS comes from Elm and update according to the model.

# Blog

The blog uses Elm for the frontend and Nodejs, with no dependencies, for the backend.

# Install

Installing the blog locally will open up a server at http://localhost:9090/elm-blog/.

Requirements:

- Nodejs 12+
- Uglifyjs 3.6.4 (`npm i -g uglify-js@3.6.4`)
- Elm 0.19.1

```shell
git clone https://github.com/dptole/elm-blog
bash elm-blog/run.sh
```

To know more about the local building process visit the [wiki][building_manually_wiki].

# Docker

In order to easily recreate the blog locally you can use the docker installer [here][docker_installer] and a local server will be available at http://localhost:9090/elm-blog/ (prod with Nodejs) and http://localhost:8080/src/Main.elm (dev with elm reactor).

```shell
git clone https://github.com/dptole/elm-blog
bash elm-blog/docker/install-container.sh
```

If you want to know more info about the `install-container.sh` process go to the [docker wiki][docker_wiki].

# Community

- [Code of conduct](CODE_OF_CONDUCT.md)
- [Contributing](CONTRIBUTING.md)

# License

[MIT][license].

[elm_0_19_1]: https://github.com/elm/compiler/blob/24d3a89469e75cf7aa579442ecaf5ddfdd192ab2/installers/linux/README.md
[demo]: https://dptole.ngrok.io/elm-blog/
[docker_installer]: https://github.com/dptole/elm-blog/blob/master/docker/install-container.sh
[docker_wiki]: https://github.com/dptole/elm-blog/wiki/Building-with-docker
[building_manually_wiki]: https://github.com/dptole/elm-blog/wiki/Building-manually
[license]: LICENSE
[travis-build]: https://travis-ci.org/dptole/elm-blog
[travis-badge-dev]: https://travis-ci.org/dptole/elm-blog.svg?branch=dev
