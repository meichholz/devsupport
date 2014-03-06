# used to DRY up the common development rake modules.

require "rake/clean"
# common settings
@browser ||= "epiphany"
@editor ||= "gvim -geometry 88x55+495-5"

