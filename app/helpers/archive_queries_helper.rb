#MPERK

module ArchiveQueriesHelper

  include AttachmentsHelper

  def retrieve_archive_query(object_type)
    query_class = Object.const_get("#{object_type.camelcase}Query")
    if !params[:query_id].blank?
      cond = "project_id IS NULL"
      cond << " OR project_id = #{@project.id}" if @project
      @query = query_class.where(cond).find(params[:query_id])
      raise ::Unauthorized unless @query.visible?
      @query.project = @project
      session["#{object_type}_query".to_sym] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear
    elsif api_request? || params[:set_filter] || session["#{object_type}_query".to_sym].nil? || session["#{object_type}_query".to_sym][:project_id] != (@project ? @project.id : nil)
      # Give it a name, required to be valid
      @query = query_class.new(:name => "_")
      @query.project = @project
      @query.build_from_params(params)
      session["#{object_type}_query".to_sym] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
    else
      # retrieve from session
      @query = query_class.find(session["#{object_type}_query".to_sym][:id]) if session["#{object_type}_query".to_sym][:id]
      @query ||= query_class.new(:name => "_", :filters => session["#{object_type}_query".to_sym][:filters], :group_by => session["#{object_type}_query".to_sym][:group_by], :column_names => session["#{object_type}_query".to_sym][:column_names])
      @query.project = @project
    end
  end

  def column_value(column, attachment, value)
    case column.name
      when :container_id
        link_to l(get_label(attachment).to_sym), container_attachments_path(attachment.container.respond_to?(:source) ? attachment.container.source : attachment.container)
      when :filename
        link_to_attachment attachment, :author => false
      when :filesize
        number_to_human_size attachment.filesize
      else
        format_object(value)
    end
  end

  def container_attachments_path(source)
    source.class.name.underscore.pluralize+"/"+source.id.to_s if source.present?
  end

  def get_label(attachment)
    if attachment.container.respond_to?(:source)
      a = "label_archive_" + attachment.container.source.class.name.underscore
    elsif(attachment.respond_to?(:container) && attachment.container.present?)
      a = "label_archive_" + attachment.container.class.name.underscore
    else
      a = "label_archive_container_deleted"
    end
    a
  end
end