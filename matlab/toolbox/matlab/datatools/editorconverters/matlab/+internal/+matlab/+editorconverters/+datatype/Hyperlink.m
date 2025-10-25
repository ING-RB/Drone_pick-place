classdef Hyperlink 
    % This class serves as data-type for HyperlinkURLEdior
    
    % Copyright 2020 The MathWorks, Inc.
    properties
        URL
    end
    
    methods
        function obj = Hyperlink(url)
            obj.URL = url;
        end
        
          function URL = getURL(obj)
            URL = obj.URL;
        end
    end
end

