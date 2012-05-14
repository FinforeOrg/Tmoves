class Admin::ScannerTasksController < ApplicationController
  layout "admin"
  before_filter :authenticate_admin!, :except => [:restart]
  before_filter :prepare_keywords, :except => [:index,:destroy]

  # GET /scanner_tasks
  # GET /scanner_tasks.xml
  def index
    @scanner_tasks = ScannerTask.all.cache
    @workers = Resque.workers
    @queues = ["AnalyzeKeywords", "DailyKeyword"]
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @scanner_tasks }
    end
  end

  # GET /scanner_tasks/1
  # GET /scanner_tasks/1.xml
  def show
    destroy
  end

  # GET /scanner_tasks/new
  # GET /scanner_tasks/new.xml
  def new
    @scanner_task = ScannerTask.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @scanner_task }
    end
  end

  # GET /scanner_tasks/1/edit
  def edit
    @scanner_task = ScannerTask.find(params[:id])
  end

  # POST /scanner_tasks
  # POST /scanner_tasks.xml
  def create
    params[:scanner_task][:keywords] = params[:keywords].join(",")
    @scanner_task = ScannerTask.new(params[:scanner_task])

    respond_to do |format|
      if @scanner_task.save
        TrackKeyword.perform_async(@scanner_task.id.to_s)
        format.html { redirect_to(admin_scanner_tasks_url, :notice => 'Scanner task was successfully created.') }
        format.xml  { render :xml => @scanner_task, :status => :created, :location => @scanner_task }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @scanner_task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /scanner_tasks/1
  # PUT /scanner_tasks/1.xml
  def update
    @scanner_task = ScannerTask.find(params[:id])
    params[:scanner_task][:keywords] = params[:scanner_task][:keywords].gsub(/\,\s/i,",")  unless params[:scanner_task][:keywords].blank?
    respond_to do |format|
      if @scanner_task.update_attributes(params[:scanner_task])
        format.html { redirect_to(admin_scanner_tasks_url, :notice => 'Scanner task was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @scanner_task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /scanner_tasks/1
  # DELETE /scanner_tasks/1.xml
  def destroy
    @scanner_task = ScannerTask.find(params[:id])

    if @scanner_task 
      @scanner_task.scanner_account.update_attribute(:is_used,false)
      @scanner_task.destroy    
    end
 
    respond_to do |format|
      format.html { redirect_to(admin_scanner_tasks_url, :notice => "Scanner Task was successfully deleted.") }
      format.xml  { head :ok }
    end
  end

  def restart
   if !params[:category].blank?
     start_queue(params[:category])
   else
     @scanner_task = ScannerTask.find(params[:id])
     TrackKeyword.perform_async(@scanner_task.id.to_s)
   end
   
   respond_to do |format|
     format.html {redirect_to(:action => :index)}
   end
  end

  def more_workers
   if !params[:queue].blank? || !params[:wid].blank?
     message = "#{params[:queue]} new worker has been added" 
     start_queue(params[:queue])
   else
     message = "No worker has been added" 
   end

   respond_to do |format|
     format.html {redirect_to(admin_scanner_tasks_url, :notice => message)}
   end
  end

  def shutdown_worker
    message = "Worker not found, please try again."
    
    Resque.workers.each do |worker|
      if worker.id == params[:wid]
        worker.unregister_worker
        message = "#{worker.id} has been unregistered successfully"
        break
      end
    end 

    respond_to do |format|
      format.html {redirect_to(admin_scanner_tasks_url, :notice => message)}
    end
  end

  private
   def prepare_keywords
     ids = ScannerTask.all.map{|x| x.scanner_account_id.to_s}
     @twitters = ScannerAccount.not_in({"_id"=>ids}).order_by(:username).only(:id,:username)
     #@twitters = ScannerAccount.order_by(:username).only(:id,:username).all
     keywords = Keyword.order_by(:title).only(:title).all.map(&:title)
     exists = ScannerTask.only(:keywords).all.map(&:keywords).join(",").split(",")
     @lists = keywords - exists
   end

   def start_queue(queue_name)
     if queue_name == 'DailyKeyword'
       DailyKeyword.perform_async
     elsif queue_name == 'AnalyzeKeywords'
       AnalyzeKeywords.perform_async
     end
   end

end
