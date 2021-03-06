# ant-wireless

home
: https://sr.ht/~ged/ruby-ant-wireless/

code
: https://hg.sr.ht/~ged/ruby-ant-wireless

docs
: https://deveiate.org/code/ant-wireless


## Description

A binding for the [ANT ultra-low power wireless protocol][ant] via the
[Garmin USB ANT Stick][antstick]. ANT can be used to send information
wirelessly from one device to another device, in a robust and flexible
manner.


## Prerequisites

* Ruby 2.7.x or later
* [Garmin USB ANT Stick][antstick]
* [ANT SDK][antsdk]

Note that we had trouble compiling the latest ANT SDK on some platforms, so we
are currently using a modified version of it with a reworked build system for
MacOS and FreeBSD, and with implementations for advanced burst and checking
initialization status. That is available under the same licensing terms at:

https://github.com/RavnGroup/Garmin-ANT-SDK


## Installation

    $ gem install ant-wireless


## Development

You can check out the current source with Git via Gitlab:

    $ hg clone https://hg.sr.ht/~ged/ruby-ant-wireless ant-wireless
    $ cd ant-wireless

After checking out the source, run:

    $ gem install -Ng
    $ rake setup

This task will install dependencies, and do any other necessary setup for development.


## Authors

- Michael Granger <ged@FaerieMUD.org>
- Mahlon E. Smith <mahlon@martini.nu>


## License

Portions of this code are from StaticCling, and are used under the
terms of the 3-Clause BSD License. Specifics can be found in the
appropriate files.

This software is:

Copyright (c) 2021, Ravn Group

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


[ant]: https://www.thisisant.com/
[antstick]: https://buy.garmin.com/en-US/US/p/10997/pn/010-01058-00
[antsdk]: https://www.thisisant.com/developer/resources/downloads/#software_tab

