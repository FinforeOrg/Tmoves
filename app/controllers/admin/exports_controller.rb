class Admin::ExportsController < ApplicationController
  layout "admin"
  before_filter :authenticate_admin!
  # GET /exports
  # GET /exports.xml
  def index
    params[:page] = params[:page].blank? ? 1 : params[:page]
    @exports = current_admin.exports.page(params[:page]).per(20)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @exports }
    end
  end

  # GET /exports/1
  # GET /exports/1.xml
  def show
    if !params[:destroy].blank?
      destroy
    else
      @export = Export.find(params[:id])
    
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @export }
      end
    end
  end

  # GET /exports/new
  # GET /exports/new.xml
  def new
    @export = Export.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @export }
    end
  end

  # GET /exports/1/edit
  def edit
    @export = Export.find(params[:id])
    @keywords = @export.keywords.split(",")
  end

  # POST /exports
  # POST /exports.xml
  def create
    @export = current_admin.exports.new
    @export.set_data(params[:export])
    respond_to do |format|
      if @export.save
        format.html { redirect_to(admin_exports_path, :notice => 'Export was successfully created.') }
        format.xml  { render :xml => @export, :status => :created, :location => @export }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @export.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /exports/1
  # PUT /exports/1.xml
  def update
    @export = Export.find(params[:id])
    @export.set_data(params[:export])
    respond_to do |format|
      if @export.save
        @export.remove_csv
        format.html { redirect_to(admin_exports_path, :notice => 'Export was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @export.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /exports/1
  # DELETE /exports/1.xml
  def destroy
    export = Export.find(params[:id])
    export.remove_csv
    export.destroy
    respond_to do |format|
      format.html { redirect_to(admin_exports_url) }
      format.xml  { head :ok }
    end
  end

  def autocomplete_keywords
    render :text => Keyword.where(:title => Regexp.new(params[:q].gsub("$", "\\$"), Regexp::IGNORECASE)).collect(&:title).join("\n")
  end

  def resume_progress
    export = Export.find(params[:id])
    respond_to do |format|
      if export.update_attribute(:status, 3)
        format.html { redirect_to(admin_export_path(export), :notice => 'Progress will be resume.') }
        format.xml  { head :ok }
      end
    end
  end

  def download
    export = Export.find(params[:id])
    send_file "#{Rails.root}/public/csv/#{export.id}/#{export.path}", :type => 'text/csv'
  end

  def update_progress
    @response = []
    if params[:ids]
      ids = params[:ids].split(",")
      exports = Export.where(:id => {"$in" => ids}).to_a
      @response = exports.map{|export| {:id => export.id, :total_progress => export.total_progress} }
    end
    respond_to do |format|
      format.html {render :text => "only support json and xml"}
      format.json  { render :json => @response }
      format.xml  { render :xml => @response }
    end
  end

end
