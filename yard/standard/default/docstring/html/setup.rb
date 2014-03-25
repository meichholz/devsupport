def init
  super
  sections.place([:fixme, :todo, :think]).after(:index)
end

def fixme
    @label = "FIX ME: "
    generic_todo :fixme
end

def todo
    @label = "TODO: "
    generic_todo :todo
end

def think
    @label = "THINK: "
    generic_todo :think
end

def generic_todo(tag)
  return unless object.has_tag?(tag)
  @tag = tag
  erb(:generic_todo)
end


