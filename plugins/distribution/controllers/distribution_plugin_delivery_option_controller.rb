class DistributionPluginDeliveryOptionController < DistributionPluginMyprofileController

  no_design_blocks

  before_filter :load

  def select
    @session = DistributionPluginSession.find params[:session_id]
    @new_delivery_method = DistributionPluginDeliveryMethod.new
    render :layout => false
  end

  def index
    @session = DistributionPluginSession.find params[:session_id]
  end

  def show
    @delivery_option = DistributionPluginSession.find params[:id]
  end

  def new
    @session = DistributionPluginSession.find params[:session_id]
    @session.update_attributes params[:session]
  end

  def destroy
    @delivery_option = @session.delivery_options.find_by_id params[:id]
    @session = @delivery_option.session
    @delivery_option.destroy
  end

  def method_destroy
    @session = DistributionPluginSession.find params[:session_id]
    @delivery_method = @node.delivery_methods.find_by_id params[:id]
    @delivery_method.destroy
  end

  def method_new
    @session = DistributionPluginSession.find params[:session_id]
    @delivery_method = DistributionPluginDeliveryMethod.create! params[:delivery_method].merge(:node => @node, :delivery_type => 'pickup')
  end

  def method_edit
    @session = DistributionPluginSession.find params[:session_id]
    @delivery_method = @node.delivery_methods.find_by_id params[:id]
    if request.post?
      @delivery_method.update_attributes! params[:delivery_method].merge(:node => @node, :delivery_type => 'pickup')
    end
  end

  protected

  def load
    @delivery_methods = @node.delivery_methods
  end

end
