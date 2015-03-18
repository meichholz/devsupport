# Devsupport

This code is my more or less personal, but extendable way to manage **maintainer mode** in our various projects.

The goal is to set up a mostly **uniform build and test** way comprising all aspects of

* Editing with Vim
* Building
* Test Driving
* TDD and BDD
* Documentation
* Packaging
* Factoring out Submodules

The resulting Boilerplate for each specific project should be **next to nil** or at least as unchanging as possible allowing to re-visit hibernating projects, when needed.

Or in another way: **Frustration free building** as platform and host independent as **affordable**.

It ist **no attempt at over-engineering** and **no claim on perfectness**.

## Inside documentation

Please see the included self-documentation by ``rake doc:view``. You need
``Yard`` for that job, and probably some browser in ``ENV['BROWSER']``.

When visiting in Jenkins, please check out the [Class List](class_list.html)
for a start.

* [Open Tasks](_todolist.html)

## Glue code for development tasks

The repo `devsupport` contains mechanics and libraries used by my various projects.

It adds higher level support to abstract from boilerplate needed to comply to various standards as

* Rubyforge/Gem
* Debian packages
* GNU projects

There is supporting stuff for

* vim
* rake driven front ends for several build styles
  * Ruby projects with Hoe
  * Ruby projects without Hoe
  * Ruby on Rails
  * C++ with CMAKE
  * C with GNU Autoconf
* yard extensions
* TDD/BDD/CI cycles and wiring

Some of this integration **is really brittle** or stubby. So use is for insprirational purposes, but not directly. OK?

## Usage as submodule

The canonical usage is inclusion as *git submodule* by the very same name.

## The basic Meta Structure

Mostly, You will need a suitable ``Rakefile``. It will do some basic steps:

1. Setup the Devsupport machinery
1. Setup Variables that cannot be or are not preset
1. Load presets for this specific project type
1. Wire some default tasks
1. Define additional tasks or overload them like in every Rakefile.

Plus, there is at least *some* tuning possibility by the environment variables or semaphore files. This is to allow co-maintainers to share the Rakefile but have at least some choices, where the Devsupport-Guesser cannot act on their behalf.

This ist mostly for the choice of the local **BROWSER**, the **EDITOR**, or debugging mode(s).

## Upstreaming or Submodules

TODO.

## About the project-environment object

Note: The accessors are normally unmutable. That is, You can *override* it, but
You cannot - for example - append a string simply.

### Defaults

TODO.

Defaults are configured not by the User project, but by the Task set.

### User Configuration.

This is the normal way to setup the project.

```
ds_configure.do |c|
  c.editfiles = [ 'README.md' ]
end
```

TODO.

### Hoe configuration

Since HOE already does *some* things that Devsupports do (with other focus and means), the typical Ruby project has a Setup at the Hoe side, and - even worse - a configuration of the Hoe integration we do here.

Again: The Goal is **reduction of boilerplate** and even Hoe cannot do without, so all we do here is to abstract away resulting boilerplate and leave at least some aspects ... configurable.

TODO.

### Conclusions

If Settings must inferred on project specific settings, which really **should**
be avoided, like a list of suitable compiler versions, or tools not fed through
the environment, some sort of post-configuration (or "conclusions") must be
applied.

TODO.

THINK: Probably ther Environment is a better choice to pass PRE-Setup-Choices.

## Build of project specific tool chains or libraries

Just one word: Google Mock and CppUTest, or the GPerfTools.

TODO.

## Examples

### Hoe based project

TODO.

### Simple Ruby project

TODO.

### GNU Autoconf based C/C++ project

TODO.

### CMAKE based C++ project

TODO.

## Suggested Vim integration

TODO.

## License

(The MIT License)

Copyright (c) 2013

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

