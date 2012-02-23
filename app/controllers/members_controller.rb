class MembersController < ApplicationController

  def new
    render :layout => false
  end
  
  def create
	user = Member.where({:email => /#{params[:member][:email]}/i}).first
	if user
	  user.update_attribute(:is_subscriber, true)
	else
	  #user = Member.create({:name => params[:name], 
	  #                      :email => params[:email], 
	  #                      :is_subscriber => params[:is_subscriber], 
	  #                      :password => "changeMe123~",
	  #                      :password_confirmation => "changeMe123~"})
          params[:member][:password] = params[:member][:password_confirmation] = "changeMe123~"
          user = Member.create(params[:member])
	end
	 
	respond_to do |format|
	  unless user.errors.any?
	    format.html {render :text => "<p>Thank you for your subscription, please confirm your email to activate subscription.</p>"}
	  else
		format.html {render :text => "<p>#{user.errors.full_messages.join(',')}</p>"}
	  end
	end
  end
  
  def unsubscribe
	member = Member.where(:email => params[:email]).first
	member.destroy if member
    respond_to do |format|
	  format.html {redirect_to "http://#{request.host}/"}
	end
  end

end
