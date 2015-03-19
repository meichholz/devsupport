# Devsupport

This code is my more or less personal, but extendable way to manage
**maintainer mode** in our various projects.

## Special Topics

To keep this document sensibly short, some topics are factored out and can be
viewed through Github or after a local YARD run, together with the YARD
reference documentation.

Since there is no compatibility between Github and Yard links styles, and even
worse, no agreed-upon table syntax, the links are given by a HTML only table
below. Apologies for that. Probably I can get the `github-markup` yard plugin running for at least the table. Stay tuned!

The documentation can be build by a ``rake doc:view``.

<table>
<tr><td>Usage in projects</td>
  <td><a href="USAGE.md">github</a></td>
  <td><a href="file.USAGE.html">local</a></td>
</tr>
<tr><td>Usage with Hoe</td>
  <td><a href="Hoe.md">github</a></td>
  <td><a href="file.Hoe.html">local</a></td>
</tr>
<tr><td>Architecture</td>
  <td><a href="Architecture.md">github</a></td>
  <td><a href="file.Architecture.html">local</a></td>
</tr>
<tr><td>A Project History </td>
  <td><a href="History.md">github</a></td>
  <td><a href="file.History.html">local</a></td>
</table>

## Goals

The goal is to set up a mostly **uniform build and test** way with **as little
additional boilerplate as possible** for various software projects.

### Extended project development cycle

There is **something** to integrate surpassing mere configuring and building,
which *may* be the point, where GNU Autoconf, Debian helpers or CMake fall
short. Full Frameworks or IDEs give an idea, where to go.

* Editing with Vim
* Building
* Test Driving
* TDD and BDD
* Documentation
* Packaging (GEM, Debian, Autoconf, CMAKE)
* Factoring out Submodules or work on them back-to-back
* Working on different hosts and platforms (Linux, MacOSX)
* Working as different team members

The resulting Boilerplate for each specific project should be **next to nil**
or at least as unchanging as possible allowing to re-visit hibernating
projects, when needed.

Or in another way: **RDF** (frustration reduced building). To be as platform and host
independent as **sensible**.

It ist **no attempt at over-engineering** and **no claim on perfectness**.

## License

(The MIT License)

Copyright (c) 2013

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

