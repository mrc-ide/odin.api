# odin.api

<!-- badges: start -->
[![Project Status: Concept – Minimal or no implementation has been done yet, or the repository is only intended to be a limited example, demo, or proof-of-concept.](https://www.repostatus.org/badges/latest/concept.svg)](https://www.repostatus.org/#concept)
[![R build status](https://github.com/mrc-ide/odin.api/workflows/R-CMD-check/badge.svg)](https://github.com/mrc-ide/odin.api/actions)
[![Build status](https://badge.buildkite.com/ca63868488c77edb9c4d6f1605a6d243d8e96da98269fb4db9.svg)](https://buildkite.com/mrc-ide/odin-dot-api)
[![codecov.io](https://codecov.io/github/mrc-ide/odin.api/coverage.svg?branch=main)](https://codecov.io/github/mrc-ide/odin.api?branch=main)
<!-- badges: end -->

## Installation

To install `odin.api`:

```r
remotes::install_github("mrc-ide/odin.api", upgrade = FALSE)
```

## Usage

```
docker pull mrcide/odin.api:main
docker run -d --rm -p 8001:8001 mrcide/odin.api:main
```

Replace `:main` with any branch or SHA, or with a version number such as `v0.1.0` for versions that have been built from `main`. If you omit the branch or use `latest` it will pull/run the last version merged to `main`.

Informational root endpoint `GET /`

```
$ curl -s http://localhost:8001 | jq
{
  "status": "success",
  "errors": null,
  "data": {
    "odin": "1.3.1",
    "odin.api": "0.1.0"
  }
}
```

Check a model with `POST /validate`

```
$ curl -s -H 'Content-Type: application/json' \
   --data '{"model": "deriv(x) <- a\ninitial(x) <- 1\na <- user(1)"}' \
   http://localhost:8001/validate | jq
{
  "status": "success",
  "errors": null,
  "data": {
    "valid": true,
    "metadata": {
      "variables": [
        "x"
      ],
      "parameters": [
        {
          "default": 1,
          "min": null,
          "max": null,
          "is_integer": false,
          "rank": 0
        }
      ],
      "messages": []
    }
  }
}
```

Invalid models will return information about where they failed (note that this will return a HTTP 200 response)

```
$ curl -s -H 'Content-Type: application/json' \
   --data '{"model": "deriv(x) <- z\ninitial(x) <- 1\na <- user(1)"}' \
   http://localhost:8001/validate | jq
{
  "status": "success",
  "errors": null,
  "data": {
    "valid": false,
    "error": {
      "message": "Unknown variable z",
      "line": [
        1
      ]
    }
  }
}

```

Compile a model with `POST /compile`

```
$ curl -s -H 'Content-Type: application/json' \
   --data '{"model": "deriv(x) <- a\ninitial(x) <- 1\na <- user(1)"}' \
   http://localhost:8001/compile | jq
{
  "status": "success",
  "errors": null,
  "data": {
    "valid": true,
    "metadata": {
      "variables": [
        "x"
      ],
      "parameters": [
        {
          "default": 1,
          "min": null,
          "max": null,
          "is_integer": false,
          "rank": 0
        }
      ],
      "messages": []
    },
    "model": "...large blob of js removed..."
  }
}
```

The generated model is subject to, and expected to, change; an example can be seen [on the old `odin.js` repository](https://github.com/mrc-ide/odin.js/#use-from-webpages).

The two `POST` endpoints will accept either a string with embedded newlines or an array of strings as input.

## License

MIT © Imperial College of Science, Technology and Medicine
