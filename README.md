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

## Design Principles<F2>

### Share code internally, be DRY

This is work in progress, because the devsupport modules started als solitons.
Later on, common tasks and presets were factored out, and this consolidates.
For example, **:cauto** and **:cmake** now share common tasks and defaults.

### Conclude as much as possible

The user gives some ideas, and the task set derives everything else.
The Taskset sets **some** defaults (it is fairly large, to be honest). The User setting wins over the default. That's all.

### Offer a stable interface

The implementation tries to be somewhat abstract to the user.
This is done by the ``setup.rb`` code, that introduces a fairly elementary DSL do interface to the user.

* ``ds_configure`` allows to tune variables
* ``ds_tasks_for`` loads a task set
* ``ds_env`` gives the resulting variable values (custom over default)

The implementing code (task sets) should use this abstraction, too, so that
there is as little internal coupling as possible.

### Clean name spacing

Global methods start with ``ds_*``. All Classes reside within the
``Devsupport`` module, however. So the user should be free to implement happily
away and use libraries, if she wants to.


### Allow tuning, where needed

Most of the time, tuning will be *optional*, not mandatory, and end up with
some assignments into a ``ds_configure`` block (see below for examples).

### Allow to get started nearly without boilerplate

The predefined task sets and defaults  **shall** be enough to start out. As
"mandatory" tuning starts to accumulate, it is time to refactor that out into
this devsupport, like with the rather demanding c support.

### Uniform appearence

OK, here we are not ready. But the idea is - really - to have the various project templates look uniform from the point of the maintainer (``rake edit`` shall call the editor, ``rake ci:all`` should start the complete task series needed by Jenkins, and so on).

There has to go some work into this, of course, like migrating the common tasks into the **ds:** namespace.

## Usage as submodule

The canonical usage is inclusion as *git submodule* by the very same name. Somewhat like this:

```
git submodule add https://github.com/meichholz/devsupport.git trunk/devsupport
git submodule init
git submodule update
```

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

The "upstream mode" is maintainer behaviour.

``rake ds:upstream`` will switch to a reloading mechanism, that will try to
reload the devsupport package from a sibling sandbox (like ``../../devsupport``
or ``../devsupport``). This is really useful to co-develop local projects and
devsupport helper, or to test drive devsupport (or simply to fix it).

``rake ds:pull`` instead will try to re-checkout the submodules (namely:
devsupport) from their currect HEAD, and it will end "upstream mode" by
clearing the semaphore file.

Pulling normally ends a devsupport maintenence cycle and allows to test drive
the project Rakefile with the "real" submodule head.

## About the project-environment object

Note: The accessors are normally unmutable. That is, You can *override* it, but
You cannot - for example - append a string simply.

### Defaults

Defaults are configured not by the user project, but by the task set. They are
stored in an own hidden instance. So, **principally**, it is up to the user to
configure before or after the task set loading.

To do this, task default configuration uses a flag.

```
ds_configure(defaults: true) do |c|
  # ...
end
```

Since ``ds_env`` evaluates lazy, timing is **normally** uncritical. However, if the defaults are to be dependent on user settings (like selection of the toolchain version) there has to be a way to sequence cleanly.

Currently that is done be the ``ds_conclude`` mechanism and hidden tasks tucked
to that frontend (TODO).

### User Configuration.

This is the normal way to setup the project.

```
ds_configure.do |c|
  c.run_arguments = '-V'
end
```

The resulting settings are visible through ``rake ds:env``.

### Hoe configuration

Since HOE already does *some* things that Devsupports do (with other focus and means), the typical Ruby project has a Setup at the Hoe side, and - even worse - a configuration of the Hoe integration we do here.

Again: The Goal is **reduction of boilerplate** and even Hoe cannot do without, so all we do here is to abstract away resulting boilerplate and leave at least some aspects ... configurable.

```
# nearly mandatory, project specific, *Hoe.spec* call, adding just necessary stuff
ds_hoe_spec(projectname) do |spec|
  spec.developer "Marian Eichholz", "marian.eichholz@freenet.ag"
end
```

### Conclusions

If Settings must inferred on project specific settings, which really **should**
be avoided, like a list of suitable compiler versions, or tools not fed through
the environment, some sort of post-configuration (or "conclusions") must be
applied.

TODO.

THINK: Probably ther Environment is a better choice to pass PRE-Setup-Choices.

## Build of project specific tool chains or libraries

Just one word: Google Mock and CppUTest. We have some "Builder" objects to
build just these critical stuff. Another candidate are the **GPerfTools** for
the **tcmalloc** library.

The front end tasks are ``build:clobber`` to get rid of the stuff and
``build:devlibs``.

Please note, that ``build:clobber`` and ``clobber`` are **not** the same. That
is, because ``rake clobber`` should NOT waste away the precious helper library
builds.

## CI/Jenkins support

### GCOV and gcovr

As it comes to code coverage, GNU has pretty much support, as long as You don't optimize Your code, and let it be instrumented. Unfortunately, the profiling data must be converted to the jenkins plugin format.

That Job is done by ``gcovr``, which we have inside this repo as a copy.

## Examples

### Hoe based project

Here is a current complete example (slightly tidied up, of course). Notice, **that there is especially low configuration**, because Hoe projects **are** streamlined by themselves.

```
load 'devsupport/tasks/setup.rb'
ds_tasks_for :hoe

projectname = ds_env.program_name
load File.join(File.dirname(__FILE__), 'lib', projectname, 'version.rb')

# @todo "tags" should be in common tasks
CLOBBER.include "tags"

# nearly mandatory, project specific, *Hoe.spec* call, adding just necessary stuff
ds_hoe_spec(projectname) do |spec|
  spec.developer "Marian Eichholz", "marian.eichholz@freenet.ag"
end

@testconfig = "-c ./config/emigma.conf -e test"

CLOBBER.include "cache/*"

# oh, this could end up as common task...
desc "Show project"
task :tree => [ :clobber ] do
  sh "tree -I devsupport"
end

namespace :run do
  # construct rake tasks for each command
  %w(config tidyup shadow update peers pubcombi announce expeers mxdn mxlist moutlist moutdn).each do |command|
    desc "Command: #{command}"
    task command do |t|
      command = t.to_s.gsub(/^.*:/,"")
      sh "bundle exec #{ds_env.frontend} #{@testconfig} -v -P #{command}"
    end
  end
end
```

Here we see the inevitable non-uniform configuration my ``ds_hoe_spec``. And
the usage of ``ds_env.projectname`` to manually bootstrap the version file,
that is needed by Hoe itself to track the package version number.

This is not really free of boilerplating and may change.

### Simple Ruby project

TODO.

### GNU Autoconf based C/C++ project

This complete(!) Rakefile is taken from a current project. 

```
load "devsupport/tasks/setup.rb"

ds_configure do |c|
  c.debug_configure_options = ""
  c.configure_options = ['--prefix=/usr',
                         '--with-gtest', '--with-gmock', '--with-cpputest',
                         '--without-gperftools',
                         ].join(' ')
  c.ci_suite_arguments = "-ojunit"
  c.gcovr_exclude = '(^(3rdparty|gtest)|(.*(CppUTest|UtestPlatform).*))'
  c.run_arguments = '-V'
  c.make_options = "--silent"
end

CLEAN.include "cpputest_*.xml"

ds_tasks_for :cauto
ds_tasks_for :devlibs
ds_conclude

task :bootstrap => ['build:devlibs']
```

### CMAKE based C++ project

It **should** be fairly symmetrical to **:cauto**, with the exeption of being another task set:

```
ds_tasks_for :cmake
ds_tasks_for :devlibs

ds_conclude
```

This is an excerpt, of course.

### Ruby on Rails project

``ds_tasks:for :rails``

## Suggested Vim integration

We have some VIM setup files in the **vim** directory. You can have a **local.vim** file with something like the following redirection in it:

```
source devsupport/vim/local_c.vim
let g:L_cext="c"
let g:L_cdotext=".c"
```

After all You are assumed to have the [Dotvim
package](https://github.com/meichholz/dotv) integrated some way.

The integration files will most of the time leave support stuff to Vim modules
by Tim Pope :-)

It is **really** advised to have at least these helpers for Vim in the toolkit:

* **vim-projectionist** for navigation
* **syntastic** for on-save-compilation-and-error
* **vim-rake** for ruby stuff (and **vim-rails** for rails)
* **syntax support** for the given languages

This - and more - is accomplished by my ``dotvim`` repo (see above).

The **vim-airline** is not needed, but I strongly advise for it, although it
calls for an (easily patched by a support script) extra X11 font. And a
terminal with **solarized** colors does really fine.

You can do without all this, and You even do not need to use Vim, because You
can select another editor by an environment variable (see below).

## Environment Variables

TODO, yes, there are some. You mostly set them off-project, because they tailor not for the project, but for **Your** need, or the needs of Your workstation.

Some guesswork ist done via availility of programms and pathes. But it is sometimes important to have the "last word".

* TODO.


## License

(The MIT License)

Copyright (c) 2013

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

