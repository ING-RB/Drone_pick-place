classdef(Sealed = true, Hidden = true) AddOnWindowUrl < handle
    %   ADDONWINDOWURL: Generates a URL with given base url and query
    %   parameters
    
    %   Copyright: 2019 The MathWorks, Inc.
    properties (Access = private)
        baseUrl
        
        queryParams = struct
    end
    
    methods (Access = public)
        
        function this = AddOnWindowUrl(baseUrl)
            this.baseUrl = baseUrl;
        end
        
        function this = addQueryParameter(this, paramName, paramValue)
            this.queryParams.(paramName) = paramValue;
        end
        
        function url = generate(this)
            if(isempty(fieldnames(this.queryParams)))
                url = matlab.net.URI(this.baseUrl);
            else
                url = matlab.net.URI(this.baseUrl, this.queryParams);
            end
            
        end
    end
end