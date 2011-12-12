class Spider < ActiveRecord::Base
  include ActAsProxy

  scope :enabled, where(:is_enabled=>true)  
  validates_uniqueness_of :ip
  validates_presence_of :ip
  validates_presence_of :connect_type
  validates_presence_of :account_id
  validates_inclusion_of :connect_type, :in => [:proxy]
  before_validation :symbolize_connect_type
  belongs_to :account
  
  def fetch url, query_data = {}, options = {}
    query_data ||= {}
    encode = options[:encoding] || 'UTF-8'
    content = method("fetch_by_#{connect_type}").call(url,query_data, options)
    content = Iconv.new('UTF-8//IGNORE', encode).iconv(content) if content.is_a?(String)
    content
  end

  def validate options = {}
    url = options[:url] || "http://www.bing.com/"
    begin
      is_enabled = !self.fetch(url).blank?
    rescue
      is_enabled = false
    end
    self.update_attributes(:is_enabled => is_enabled, :last_validated_at => Time.now)
  end
  
  protected
  
  def symbolize_connect_type
    self.connect_type = self.connect_type.to_sym if self.connect_type
  end
end
