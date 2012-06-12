
class HostsController < ApplicationController

  def index
    @hosts = Host.all
    bootstrap @hosts
    restful @hosts
  end

  def show
    @host = Host.find(params[:id])
    restful @host
  end

  def update
    @host = Host.find(params[:id])
    @host.update_attributes pick(:alias, :desc)
    respond_with(@host)
  end

end