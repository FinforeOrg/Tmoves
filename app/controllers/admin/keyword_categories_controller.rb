class Admin::KeywordCategoriesController < ApplicationController
  # GET /keyword_categories
  # GET /keyword_categories.xml
  def index
    @categories = KeywordCategory.all.asc(:index_at)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @keyword_categories }
    end
  end

  # GET /keyword_categories/1
  # GET /keyword_categories/1.xml
  def show
    @category = KeywordCategory.find(params[:id])
    @category.destroy if @category
    respond_to do |format|
      format.html admin_keyword_categories_url
      format.xml  { render :xml => @category }
    end
  end

  # GET /keyword_categories/new
  # GET /keyword_categories/new.xml
  def new
    @category = KeywordCategory.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @category }
    end
  end

  # GET /keyword_categories/1/edit
  def edit
    @category = KeywordCategory.find(params[:id])
  end

  # POST /keyword_categories
  # POST /keyword_categories.xml
  def create
    params[:keyword_category][:index_at] = KeywordCategory.size + 1
    @category = KeywordCategory.new(params[:keyword_category])

    respond_to do |format|
      if @category.save
        format.html { redirect_to admin_keyword_categories_url, :notice => 'Keyword category was successfully created.' }
        format.xml  { render :xml => @category, :status => :created, :location => @category }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /keyword_categories/1
  # PUT /keyword_categories/1.xml
  def update
    @category = KeywordCategory.find(params[:id])

    respond_to do |format|
      if @category.update_attributes(params[:keyword_category])
        format.html { redirect_to admin_keyword_categories_url, :notice => 'Keyword category was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /keyword_categories/1
  # DELETE /keyword_categories/1.xml
  def destroy
    @category = KeywordCategory.find(params[:id])
    @category.destroy

    respond_to do |format|
      format.html { redirect_to(admin_keyword_categories_url) }
      format.xml  { head :ok }
    end
  end
  
  def save_orders
    notification = "no orders have been made."
    if !params[:orders].blank?
      orders = params[:orders].gsub(/\,$/,"").split(",")
      counter = 1
      orders.each do |kc_id|
        category = KeywordCategory.find(kc_id) 
        if category
          category.update_attribute(:index_at,counter)
          counter += 1
        end
      end
      notification = "Keyword Categories have been ordered successfully."
    end

    respond_to do |format|
      format.html { redirect_to(admin_keyword_categories_url, :notice => notification) }
      format.xml  { head :ok }
    end
  end

end
