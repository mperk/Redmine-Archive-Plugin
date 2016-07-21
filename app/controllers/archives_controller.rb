#MPERK

class ArchivesController < ApplicationController

  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  helper :archive_queries
  include ArchiveQueriesHelper

  def index
    retrieve_archive_query('archive')
    sort_init(@query.sort_criteria.empty? ? [['created_on', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      case params[:format]
        when 'csv', 'pdf'
          @limit = Setting.issues_export_limit.to_i
        else
          @limit = per_page_option
      end

      @archive_count = @query.object_count
      @archive_pages = Paginator.new @archive_count, @limit, params['page']
      @offset ||= @archive_pages.offset
      @archive_count_by_group = @query.object_count_by_group
      @archives = @query.results_scope(:search => params[:search],
                                       :order => sort_clause,
                                       :offset => @offset,
                                       :limit => @limit)
      respond_to do |format|
        format.html {render :template => 'archives/index', :layout => !request.xhr?  }
      end
    else
      respond_to do |format|
        format.html { render(:template => 'archives/index', :layout => !request.xhr?) }
      end
    end
  end

end
