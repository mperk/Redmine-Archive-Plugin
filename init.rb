require 'redmine'

# ActionDispatch::Callbacks.to_prepare do
#   require 'redmine_archive'
# end

Redmine::Plugin.register :redmine_archive do
  name 'Redmine Archive Plugin'
  description 'This is a Archive Plugin for Redmine'
  author 'Mehmet PERK'
  author_url 'perkmehmed@gmail.com'
  #requires_redmine :version_or_higher => '2.1.0'
  version '0.0.1'
  #url 'https://github.com/'

  menu :top_menu, :archives, {:controller => 'archives', :action => 'index', :project_id => nil},
       :caption => :label_archive_plural,
       :if => Proc.new{ User.current.allowed_to?({:controller => 'archives', :action => 'index'},
                                                 nil, {:global => true})}

  project_module :archives do
    permission :view_archives, {
        :archives => [:index]
    }
  end

  menu :project_menu, :archives, {:controller => 'archives', :action => 'index' },
       :caption => :label_archive_plural,
       :param => :project_id

end
