# README

![](https://geojs.io/img/logo.png)

 A highly available backendless geo-location lookup API

 [![](https://img.shields.io/circleci/project/github/jloh/geojs.svg)](https://circleci.com/gh/jloh/geojs) [![Coverage Status](https://coveralls.io/repos/github/jloh/geojs/badge.svg?branch=master)](https://coveralls.io/github/jloh/geojs?branch=master) ![](https://img.shields.io/github/release/jloh/geojs.svg) ![](https://img.shields.io/github/license/jloh/geojs.svg) [![](https://img.shields.io/gitter/room/jloh/geojs.svg?logo=gitter-white)](https://gitter.im/jloh/geojs)

 [![](https://img.shields.io/badge/slack-app-E01765.svg)](https://jloh.slack.com/apps/A6WCHU48J-geojs) [![](https://img.shields.io/badge/twist-app-46bc99.svg)](https://twistapp.com/integrations/install/198_a1a4dc4678cb01d89cdc4533) [![](https://img.shields.io/badge/hipchat-app-003366.svg)](https://marketplace.atlassian.com/plugins/com.jloh.geojs/server/overview)

## Introduction

GeoJS is a geo-location lookup API supporting plain text, JSON and JSONP endpoints. It also has [ChatOps integration](https://geojs.io/docs/chatops/) and a PTR endpoint. With full CORS support GeoJS can be integrated into any frontend or backend app easily.

### Repos

The GeoJS website is available over at [jloh/geojs-io](https://github.com/jloh/geojs-io) and webapp at [jloh/geojs-app](https://github.com/jloh/geojs-app).

## Installation / Getting started

Want your IP? [Easy](https://get.geojs.io/v1/ip).

```text
$ curl -s https://get.geojs.io/v1/ip
8.8.8.8
```

Need a PTR? [Surething](https://get.geojs.io/v1/dns/ptr)!

```text
$ curl -s https://get.geojs.io/v1/dns/ptr
google-public-dns-a.google.com
```

I want to know what country a specific IP belongs to! [I gotchu](https://get.geojs.io/v1/ip/country/8.8.8.8).

```text
$ curl -s https://get.geojs.io/v1/ip/country/8.8.4.4
US
```

Checkout the GeoJS [web app](https://app.geojs.io) for a real world example.

GeoJS has a free unlimited production instance running at [get.geojs.io](https://get.geojs.io/v1/ip) however if you need to host an instance yourself follow on below.

ToDo!

## Contributing

We use [Waffle](https://waffle.io/jloh/geojs) to track our work, feel free to tackle anything in the _To Do_ column.

Pull requests are warmly welcome!

## Sponsors

GeoJS runs on Digital Ocean's cloud computing platform. Use the link below to get $10 on signup and support GeoJS going forward.

 [![Digital Ocean](https://geojs.io/img/DO_Logo_horizontal_blue.svg)](https://m.do.co/c/2c9ab4daaa8d/)

## Licence

```text
MIT License

Copyright (c) 2017-2018 James Loh

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

