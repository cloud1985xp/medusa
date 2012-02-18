class CrawlerController < ApplicationController
  include ActAsAuthable
  act_as_authable
  
  def fetch
    render_by_format handle_by_action
  end
  
  protected
  def handle_by_action
    raise "missing parameter : url" unless params[:url]
    @options = params[:options] || {}
    spider = @options[:ip] ? Spider.find_by_ip_and_is_enabled(@options[:ip], true) : DomainCrawling.pick_spider(params[:url])
    if spider
      data = send "handle_#{params[:action]}", spider
      DomainCrawling.crawled(spider, params[:url]) if data[:status] == 200
    else
      raise "no spiders!"
    end
    AppCrawling.create!(:app => @app, :url => params[:url]) if @app && !@options[:disable_log]
    data
  end
  def handle_fetch spider
    data = spider.fetch(params[:url], params[:query], :encoding => @options[:encoding])
    data = spider.response_code unless spider.fetch_success?
    render_fetch data
  end
  def render_fetch data
    result = {
      :method=>request.method.downcase,
      :url=>params[:url],:query=>params[:query]
    }
    if data.is_a?(Fixnum)
      result[:status] = data
    else
      result[:data] = data
      result[:status] = 200
    end
    result
  end
  def render_by_format data
    respond_to do |f|
      f.html {render :text => data[:data].to_s}
      f.json {render :json => data.to_json}
      f.xml {render :xml => data.to_xml}
    end
  end
end
