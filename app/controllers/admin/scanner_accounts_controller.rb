class Admin::ScannerAccountsController < ApplicationController
  layout "admin"
  before_filter :authenticate_admin!, :except => [:auth,:callback]
  before_filter :prepare_callback, :only => [:auth]
  before_filter :prepare_oauth_consumer, :only => [:auth,:callback]

  # GET /scanner_accounts
  # GET /scanner_accounts.xml
  def index
    @scanner_accounts = ScannerAccount.all.cache

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @scanner_accounts }
    end
  end

  # GET /scanner_accounts/1
  # GET /scanner_accounts/1.xml
  def show
    destroy
  end

  # GET /scanner_accounts/new
  # GET /scanner_accounts/new.xml
  def new
    @scanner_account = ScannerAccount.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @scanner_account }
    end
  end

  # GET /scanner_accounts/1/edit
  def edit
    @scanner_account = ScannerAccount.find(params[:id])
  end

  # POST /scanner_accounts
  # POST /scanner_accounts.xml
  def create
    @scanner_account = ScannerAccount.new(params[:scanner_account])

    respond_to do |format|
      if @scanner_account.save
        format.html { redirect_to(admin_scanner_accounts_url, :notice => "#{@scanner_account.username} was successfully created.") }
        format.xml  { render :xml => @scanner_account, :status => :created, :location => @scanner_account }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @scanner_account.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /scanner_accounts/1
  # PUT /scanner_accounts/1.xml
  def update
    @scanner_account = ScannerAccount.find(params[:id])

    respond_to do |format|
      if @scanner_account.update_attributes(params[:scanner_account])
        format.html { redirect_to(admin_scanner_accounts_url, :notice => "#{@scanner_account.username} was successfully updated.") }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @scanner_account.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /scanner_accounts/1
  # DELETE /scanner_accounts/1.xml
  def destroy
    @scanner_account = ScannerAccount.find(params[:id])
    @scanner_account.destroy

    respond_to do |format|
      format.html { redirect_to(admin_scanner_accounts_url, :notice => "#{@scanner_account.username} was successfully deleted.") }
      format.xml  { head :ok }
    end
  end

  def auth
    session['social_login'] ||= {}
    request_token = @consumer.get_request_token({:oauth_callback => @callback_url})
    auth_url = request_token.authorize_url({:force_login => 'false'})
    session['social_login'][@cat] = {:rt=>request_token.token, :rs=>request_token.secret, :acct_id => params[:acct_id]}

    respond_to do |format|
      format.html {redirect_to auth_url}
    end
  end

  def callback
    if !params[:cat].blank? && !session['social_login'].blank?
      @cat = params[:cat]
      stored_data = session['social_login'][@cat]
      if !stored_data.blank?
        twitter_api = TwitterApi.first
        request_token = OAuth::RequestToken.new(@consumer,stored_data[:rt],stored_data[:rs])
        access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
        screen_name = twitter_screen_name(access_token)

        if !stored_data[:acct_id].blank?
          account = ScannerAccount.find(stored_data[:acct_id])
          account.update_attributes({:username => screen_name, :token => access_token.token, :secret => access_token.secret})
        else
          account = ScannerAccount.create({:username => screen_name, :token => access_token.token, :secret => access_token.secret})
        end

        session['social_login'][@cat] = nil

      end
    end

    respond_to do |format|
      if account
        format.html {redirect_to admin_scanner_accounts_url, :notice => "#{account.username} was successfully authenticated."}
      else
        format.html {render :text => "Session Time Out"}
      end
    end
  end

  private
    def prepare_oauth_consumer
      twitter_api = TwitterApi.first
      client_option = {:site => 'https://api.twitter.com', :authorize_path => '/oauth/authorize' }
      @consumer = OAuth::Consumer.new(twitter_api.consumer_key, twitter_api.consumer_secret, client_option)
    end

    def prepare_callback
      @cat = generate_code if @cat.blank?
      @callback_url = "http://#{request.host}/admin/scanner_accounts/callback?cat=#{@cat}"
    end

    def twitter_screen_name(access_token)
      person = MultiJson.decode(access_token.get('/1/account/verify_credentials.json').body)
      return person['screen_name']
    end

end
