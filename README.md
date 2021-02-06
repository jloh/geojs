# README

![](https://geojs.io/img/logo.png)

 A highly available backendless geo-location lookup API

 [![](https://img.shields.io/circleci/project/github/jloh/geojs.svg)](https://circleci.com/gh/jloh/geojs) [![Coverage Status](https://coveralls.io/repos/github/jloh/geojs/badge.svg?branch=master)](https://coveralls.io/github/jloh/geojs?branch=master) ![](https://img.shields.io/github/release/jloh/geojs.svg) ![](https://img.shields.io/github/license/jloh/geojs.svg) [![](https://img.shields.io/gitter/room/jloh/geojs.svg?logo=gitter-white)](https://gitter.im/jloh/geojs)

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

GeoJS has a free unlimited production instance running at [get.geojs.io](https://get.geojs.io/v1/ip).

## Sponsors

GeoJS is powered by the DigitalOcean cloud and wouldn't be possible without them. Use our [referral link](https://m.do.co/c/2c9ab4daaa8d) to get $10 free credit upon signup. We'd also like to thank [DNS Spy](https://www.dnsspy.io/?ref=geojs.io ) who continually monitor our DNS infrastructure to ensure that users can reach GeoJS. Finally we want to thank Cloudflare who power our frontend traffic and enable us to cache our heavily dynamic API.

![](https://geojs.io/img/DO_Logo_horizontal_blue.svg)

![](https://geojs.io/img/DO_Logo_horizontal_blue.svg)
![](https://geojs.io/img/dnsspy_logo.png)
![](https://geojs.io/img/cloudflare_logo.png)
 
## Licence

```text
MIT License

Copyright (c) 2017-2021 James Loh

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
