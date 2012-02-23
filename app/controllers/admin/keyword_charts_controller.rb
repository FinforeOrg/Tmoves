class Admin::KeywordChartsController < ApplicationController
  before_filter :prepare_chart_types, :except => [:index, :destroy]
  # GET /keyword_charts
  # GET /keyword_charts.xml
  def index
    @keyword_charts = KeywordChart.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @keyword_charts }
    end
  end

  # GET /keyword_charts/1
  # GET /keyword_charts/1.xml
  def show
    @keyword_chart = KeywordChart.find(params[:id])
    @keyword_chart.delete if @keyword_chart
    respond_to do |format|
      format.html { redirect_to admin_keyword_charts_path }
      format.xml  { render :xml => @keyword_chart }
    end
  end

  # GET /keyword_charts/new
  # GET /keyword_charts/new.xml
  def new
    @keyword_chart = KeywordChart.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @keyword_chart }
    end
  end

  # GET /keyword_charts/1/edit
  def edit
    @keyword_chart = KeywordChart.find(params[:id])
  end

  # POST /keyword_charts
  # POST /keyword_charts.xml
  def create
    @keyword_chart = KeywordChart.new(params[:keyword_chart])

    respond_to do |format|
      if @keyword_chart.save
        format.html { redirect_to(admin_keyword_charts_path, :notice => 'Keyword chart was successfully created.') }
        format.xml  { render :xml => @keyword_chart, :status => :created, :location => @keyword_chart }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @keyword_chart.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /keyword_charts/1
  # PUT /keyword_charts/1.xml
  def update
    @keyword_chart = KeywordChart.find(params[:id])

    respond_to do |format|
      if @keyword_chart.update_attributes(params[:keyword_chart])
        format.html { redirect_to(admin_keyword_charts_path, :notice => 'Keyword chart was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @keyword_chart.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /keyword_charts/1
  # DELETE /keyword_charts/1.xml
  def destroy
    @keyword_chart = KeywordChart.find(params[:id])
    @keyword_chart.destroy

    respond_to do |format|
      format.html { redirect_to(keyword_charts_url) }
      format.xml  { head :ok }
    end
  end

  private
    def prepare_chart_types
      @chart_types = ChartType.all.map{|ct| [ct.id, ct.title]}
    end

end
