# Devsupport from a client (user) perspective

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


