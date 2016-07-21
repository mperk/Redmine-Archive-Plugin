#MPERK

class ArchiveQuery < Query

  self.queried_class = Attachment

  self.available_columns = [
      #QueryColumn.new(:id, :sortable => "#{Attachment.table_name}.id", :default_order => 'desc', :caption => '#', :frozen => true),
      QueryColumn.new(:container_id, :caption => :label_archive_container),
      #QueryColumn.new(:container_type, :sortable => "#{Attachment.table_name}.container_type", :groupable => true, :caption => :label_archive_container_type),
      QueryColumn.new(:filename, :sortable => "#{Attachment.table_name}.filename", :caption => :label_archive_filename),
      QueryColumn.new(:filesize, :sortable => "#{Attachment.table_name}.filesize", :caption => :label_archive_filesize),
      #QueryColumn.new(:content_type, :sortable => "#{Attachment.table_name}.content_type", :caption => :label_archive_content_type),
      QueryColumn.new(:description, :caption => :label_archive_description),
      QueryColumn.new(:author, :sortable => lambda {User.fields_for_order_statement("authors")}, :groupable => true),
      QueryColumn.new(:created_on, :sortable => "#{Attachment.table_name}.created_on", :default_order => 'desc')
  ]

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= {}
  end

  def initialize_available_filters
    #add_available_filter "container_id", :type => :string, :label => :label_archive_container
    #add_available_filter "container_type", :type => :string, :label => :label_archive_container_type
    add_available_filter "filename", :type => :string, :label => :label_archive_filename
    #add_available_filter "filesize", :type => :string, :label => :label_archive_filesize
    #add_available_filter "content_type", :type => :string, :label => :label_archive_content_type
    add_available_filter("author_id",  :type => :list_optional, :values => users_values) unless users_values.empty?
    add_available_filter "created_on", :type => :date_past
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns
  end

  def default_columns_names
    @default_columns_names ||= [:id, :container_id,  :container_type, :filename, :filesize, :author, :created_on]
  end

  def objects_scope(options={})
    scope = Attachment.where("container_id is not null") # where.not(container_id: nil) > Rails 4
    options[:search].split(' ').collect{ |search_string| scope = scope.live_search(search_string) } unless options[:search].blank?
    scope = scope.includes(((options[:include] || [])).uniq).
        where(statement).
        where(options[:conditions])
    scope
  end

  def object_count
    objects_scope.count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def query_includes
    includes = [:container]
    includes
  end

  def principals
    return @principals if @principals
    @principals = []
    if project
      @principals += project.principals.sort
      unless project.leaf?
        subprojects = project.descendants.visible.all
        @principals += Principal.member_of(subprojects)
      end
    else
      if all_projects.any?
        @principals += Principal.member_of(all_projects)
      end
    end
    @principals.uniq!
    @principals.sort!
  end

  def users_values
    return @users_values if @users_values
    users = principals.select {|p| p.is_a?(User)}
    @users_values = []
    @users_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    @users_values += users.collect{|s| [s.name, s.id.to_s] }
    @users_values
  end

  def object_count_by_group
    r = nil
    if grouped?
      begin
        # Rails3 will raise an (unexpected) RecordNotFound if there's only a nil group value
        r = objects_scope.
            joins(joins_for_order_statement(group_by_statement)).
            group(group_by_statement).count
      rescue ActiveRecord::RecordNotFound
        r = {nil => object_count}
      end
      c = group_by_column
      if c.is_a?(QueryCustomFieldColumn)
        r = r.keys.inject({}) {|h, k| h[c.custom_field.cast_value(k)] = r[k]; h}
      end
    end
    r
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def results_scope(options={})
    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)
    objects_scope(options).
        order(order_option).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset])
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

end