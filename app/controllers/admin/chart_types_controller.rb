class Admin::ChartTypesController < ApplicationController
  before_filter :prepare_category, :except => [:index, :destroy]
  # GET /chart_types
  # GET /chart_types.xml
  def index
    @chart_types = ChartType.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @chart_types }
    end
  end

  # GET /chart_types/1
  # GET /chart_types/1.xml
  def show
    @chart_type = ChartType.find(params[:id])
    @chart_type.destroy if @chart_type
    respond_to do |format|
      format.html { redirect_to admin_chart_types_url }
      format.xml  { render :xml => @chart_type }
    end
  end

  # GET /chart_types/new
  # GET /chart_types/new.xml
  def new
    @chart_type = ChartType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @chart_type }
    end
  end

  # GET /chart_types/1/edit
  def edit
    @chart_type = ChartType.find(params[:id])
  end

  # POST /chart_types
  # POST /chart_types.xml
  def create
    @chart_type = ChartType.new(params[:chart_type])

    respond_to do |format|
      if @chart_type.save
        format.html { redirect_to(admin_chart_types_url, :notice => 'Chart type was successfully created.') }
        format.xml  { render :xml => @chart_type, :status => :created, :location => @chart_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @chart_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /chart_types/1
  # PUT /chart_types/1.xml
  def update
    @chart_type = ChartType.find(params[:id])

    respond_to do |format|
      if @chart_type.update_attributes(params[:chart_type])
        format.html { redirect_to(admin_chart_types_url, :notice => 'Chart type was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @chart_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /chart_types/1
  # DELETE /chart_types/1.xml
  def destroy
    @chart_type = ChartType.find(params[:id])
    @chart_type.destroy

    respond_to do |format|
      format.html { redirect_to(chart_types_url) }
      format.xml  { head :ok }
    end
  end

  private
    def prepare_category
      @categories = ["TimeLine","Sticks","Lines"]
    end

end
