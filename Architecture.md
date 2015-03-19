# Devsupport: Inner workings and architecture

In order to get the most out of it, or to add or change behaviour, You have to delve into the code. There is no way around it. Apologies.

## Design Principles

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

