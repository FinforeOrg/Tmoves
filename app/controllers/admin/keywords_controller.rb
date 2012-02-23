class Admin::KeywordsController < ApplicationController
  layout "admin"
  before_filter :prepare_categories, :except => [:destroy]
  # GET /keywords
  # GET /keywords.xml
  def index
    params[:page] = params[:page].blank? ? 1 : params[:page]
    @category = KeywordCategory.find(params[:cat]) unless params[:cat].blank?

    if @category
      @keywords = @category.keywords
      sort_keywords unless @category.sorted_keywords.blank?
    else
      @keywords = Keyword.includes([:keyword_category]).order_by(:title.asc).page(params[:page]).per(20).cache
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @keywords }
      format.json { render :json =>@keywords }
    end
  end

  # GET /keywords/new
  # GET /keywords/new.xml
  def new
    @keyword = Keyword.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @keyword }
    end
  end

  # GET /keywords/1/edit
  def edit
    @keyword = Keyword.find(params[:id])
  end

  # POST /keywords
  # POST /keywords.xml
  def create
    @keyword = Keyword.new(params[:keyword])

    respond_to do |format|
      if @keyword.save
        prepare_dependencies_data
        format.html { redirect_to(admin_keywords_url, :notice => "#{@keyword.title} was successfully created.") }
        format.xml  { render :xml => @keyword, :status => :created, :location => @keyword }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @keyword.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /keywords/1
  # PUT /keywords/1.xml
  def update
    @keyword = Keyword.find(params[:id])

    respond_to do |format|
      if @keyword.update_attributes(params[:keyword])
        format.html { redirect_to(admin_keywords_url, :notice => "#{@keyword.title} was successfully updated.") }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @keyword.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @keyword = Keyword.find(params[:id])
    @keyword.destroy

    respond_to do |format|
      format.html { redirect_to(admin_keywords_url, :notice => "#{@keyword.title} was successfully deleted.") }
      format.xml  { head :ok }
    end
  end

  def save_orders
    notification = "no orders have been made."
    if !params[:cat].blank?
      category = KeywordCategory.find(params[:cat])
      if category && !params[:orders].blank?
       category.update_attribute(:sorted_keywords,params[:orders].gsub(/\,$/,""))
       notification = "Keywords for #{category.title} have been ordered successfully."
      end
    end

    respond_to do |format|
      format.html { redirect_to(admin_keywords_url({:cat => params[:cat]}), :notice => notification) }
      format.xml  { head :ok }
    end
  end

  private
    def prepare_categories
      @categories = KeywordCategory.all
    end

    def sort_keywords
      match_keywords = []
      diff_keywords = []
      tmp_keywords = @keywords.to_a
      @category.sorted_keywords.split(",").each do |key|
        tmp_keywords.each do |keyword|
          if key == keyword.id.to_s
            match_keywords.push(keyword)
            break
          end
        end
      end
      diff_keywords = tmp_keywords - match_keywords
      @keywords = match_keywords + diff_keywords
    end

    def prepare_dependencies_data
      KeywordTraffic.create({:keyword_id => @keyword.id})
      chart_types = ChartType.all
      chart_types.each do |chart_type|
        KeywordChart.create({:keyword_id => @keyword.id, :chart_type_id => chart_type.id})
      end
    end
end
