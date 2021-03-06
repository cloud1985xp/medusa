module ActAsAuthable
  extend ActiveSupport::Concern
  module ClassMethods
    def act_as_authable
      before_filter :authenticate_app, :only=>[:fetch]
    end
  end
  module InstanceMethods
    
    protected
    
    def authenticate_app
      @app = authenticating(params[:token])
      raise "token fail" if !@app
    end
    
    private
    
    def authenticating token
      app = nil
      if !token.blank?
        app = App.find_by_token(params[:token])
      end
      app
    end
  end
  
end