require 'sys/proctable'
require 'sequel'

TEMPLATES = 'templates/'
DEFAULT_BASE = TEMPLATES + 'base.eruby'
DEFAULT_TITLE = 'The administrator tool'
HOME = ENV["HOME"] 
RADMIN_HOME = HOME + "/.radministrator"

DB = Sequel.connect("sqlite://data.db")

def init_db
  init_procs
end

def init_procs
  return if DB.table_exists? :monitored_procs
  DB.create_table :monitored_procs do
    primary_key :id
    String :cmdline    
  end
end

def format_to_html(output)
  output.gsub("\n", "<br />")
end

def _render(template_name, options = {}, title = DEFAULT_TITLE,  base_name = DEFAULT_BASE)
  template_name = template_name.to_s
  template = File.read(TEMPLATES + template_name + '.eruby')
  html = Erubis::Eruby.new(template).result(options)
  base_template = File.read(base_name)
  base = Erubis::Eruby.new(base_template)
  base.result(:title => title, :html => html)
end

def register_server
  Dir.mkdir RADMIN_HOME unless File.exists? RADMIN_HOME
  f = File.open(RADMIN_HOME + '/process.pid', "w")
  f.write(Process.pid)
end

def add_proc_to_monitor(procname)
  procs = DB[:monitored_procs]
  return if procs.where(:cmdline => procname).count > 0
  procs.insert(:cmdline => procname)  
end

def del_proc_from_monitor(procname)
  procs = DB[:monitored_procs]
  return if procs.where(:cmdline => procname).count == 0
  procs.where(:cmdline => procname).delete
end

def monitored_procs
  procnames = DB[:monitored_procs].all.map{|p| p[:cmdline]}.join("|")
  return [] if procnames == ""
  all_procs.select{|p| p.cmdline =~ /#{procnames}/i}
end

def all_procs
  Sys::ProcTable.ps
end

init_db
