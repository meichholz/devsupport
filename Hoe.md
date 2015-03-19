# Devsupport with Hoe

There is much to be said about hoe as gold-standard of GEM project management.

It is an extensible Framework by it's own right, and I/we use just a small
fraction of it, mainly to get things DRYed out.

DRY as it is, it leaves a good fraction of Repetition in projects, although
they **can** be addressed by Hoe plugins. But I didn't want to go that way too
far with own Hoe-Gems.

Instead, we integrate Hoe plugins (in fact: just one: Hoe-Devsupport) and
invoke it mandatorily.

That way, Hoe and Devsupport can share information to keep things DRY.

So far for the theory ;-)

## The Hoe plugin

TODO.

## Hoe Speccing

Since HOE already does *some* things that Devsupports do (with other focus and
means), the typical Ruby project has a Setup at the Hoe side, and - even worse
- a configuration of the Hoe integration we do here.

Again: The Goal is **reduction of boilerplate** and even Hoe cannot do without,
so all we do here is to abstract away resulting boilerplate and leave at least
some aspects ... configurable.

```
# nearly mandatory, project specific, *Hoe.spec* call, adding just necessary stuff
ds_hoe_spec(projectname) do |spec|
  spec.developer "Marian Eichholz", "marian.eichholz@freenet.ag"
end
```

Think of it as kind of Hoe-Callback for the user to override settings.

## Example

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

