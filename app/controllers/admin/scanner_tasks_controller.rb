class Admin::ScannerTasksController < ApplicationController
  layout "admin"
  before_filter :authenticate_admin!, :except => [:restart]
  before_filter :prepare_keywords, :except => [:index,:destroy]

  # GET /scanner_tasks
  # GET /scanner_tasks.xml
  def index
    @scanner_tasks = ScannerTask.all.cache
    @workers = Resque.workers
    @queues = ["Savetweetresult", "StreamTrack", "DailyFollower", "DailyKeyword"]
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
        prepare_scanner_task
	@scanner_task.scanner_account.update_attribute(:is_used,true)
        system "/usr/bin/rake resque:work QUEUE=StreamTrack RAILS_ENV=production &"
        Resque.enqueue(Finforenet::Jobs::Background, @scanner_task.id.to_s)
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
      kill_process = "StreamTrack"
      Resque.workers.each do |worker|
        if worker.processing["queue"] == kill_process
          worker.unregister_worker
          break
        end
      end 

      @scanner_task.scanner_account.update_attribute(:is_used,false)
      @scanner_task.destroy    
      CACHE.delete("account_#{@scanner_task.id.to_s}")
      CACHE.delete("dictionary_#{@scanner_task.id.to_s}")
      CACHE.delete("keyword_#{@scanner_task.id.to_s}")
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
     Resque.enqueue(Finforenet::Jobs::Background, @scanner_task.id.to_s)
   end
   
   respond_to do |format|
     format.html {redirect_to(:action => :index)}
   end
  end

  def more_workers
   if !params[:queue].blank? || !params[:wid].blank?
     message = "#{params[:queue]} new worker has been added" 
     if params[:wid].blank?
       system "/usr/bin/rake resque:work QUEUE=#{params[:queue]} RAILS_ENV=production &" 
     else
       params[:queue] = params[:wid].split(":").pop
     end
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

   def prepare_scanner_task
     @account = @scanner_task.scanner_account
     CACHE.set("account_#{@scanner_task.id.to_s}",{:username=>@account.username,:password=>@account.password, :token => @account.token, :secret=> @account.secret}) 
     CACHE.set("keyword_#{@scanner_task.id.to_s}",@scanner_task.keywords) 
     all_keywords = @scanner_task.keywords.split(',').map{|k|
     		          if k.include?("$")
			     k = k.gsub("$","[$]")
                             "#{k}\s|#{k}$"
            		  else
		             k
               		  end
	              }.join("|")
     CACHE.set("dictionary_#{@scanner_task.id.to_s}",all_keywords) 
   end

   def start_queue(queue_name)
     if queue_name == 'WeeklyKeyword'
       Resque.enqueue(Finforenet::Jobs::Bg::WeeklyKeyword)
     elsif queue_name == 'DailyKeyword'
       Resque.enqueue(Finforenet::Jobs::Bg::DailyKeyword)
     elsif queue_name == 'DailyFollower'
       Resque.enqueue(Finforenet::Jobs::Bg::DailyFollower)
     elsif queue_name == 'Savetweetresult'
       Resque.enqueue(Finforenet::Jobs::Bg::Savetweetresult)
     elsif queue_name == 'MigrationDigger'
       Resque.enqueue(Finforenet::Jobs::Bg::MigrationDigger)
     elsif queue_name == 'MonthlyKeyword'
       Resque.enqueue(Finforenet::Jobs::Bg::MonthlyKeyword)
     elsif queue_name == 'RepairDaily'
       Resque.enqueue(Finforenet::Jobs::Bg::RepairDaily)
     elsif queue_name == 'ImportElastic'
       Resque.enqueue(Finforenet::Jobs::Bg::ImportElastic)
     elsif queue_name == 'MonthlyKeyword'
        Resque.enqueue(Finforenet::Jobs::Bg::MonthlyKeyword)
     end
	 #Resque.redis.del "queue:Savetweetresult"
   end

end
