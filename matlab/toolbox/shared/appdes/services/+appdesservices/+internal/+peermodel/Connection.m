classdef Connection < handle
    % CONNECTION  starts the connector and composes the URL for the browser
    % client web page
    %
    %   When this class is created, the connector will be started.
    %
    %   Note that the connector is NOT stopped when this class is
    %   destroyed.

    %   Copyright 2013 - 2016 The MathWorks, Inc.
    
    properties( SetAccess=private)
        % The absolute URL path of the web page
        AbsoluteUrlPath
    
        % The last URL given by the user
        %
        % This is stored because on a refresh call... a unique URL with a
        % nonce needs to be re-generated
        RelativeUrl
    end
    
    
    methods
        % constructor for the Connection object
        function obj = Connection(pathToWebPage)
            setUrl(obj, pathToWebPage);
        end
    end
    
    methods
        function setUrl(obj, relativeUrl)
            % setUrl
            %
            % Sets the URL of the current connection object
            %
            % This URL will be preppended with localhost/<portnumber>
            %
            % This URL will also be nonced.
            
            assert(ischar(relativeUrl), 'relativeUrl must be a string');
            
            % Store
            obj.RelativeUrl = relativeUrl;
            
            % Calculate the URL
            refresh(obj);            
        end
        
        function refresh(obj, queryString)
            % Refreshes the URL with a fresh nonce
            %
            % This should be used if a web - browser is ever re-loaded in a
            % MATLAB session
            %
            % i.e. opening app designer, closing it, and then wanting to
            % re-open
            %
            % queryString: an optional argument - to generate absolute URL
            % with query string provided
            
            % Wait for connector fully going on, otherwise any calling to
            % connector or peer model related functionalities will fail
            connector.ensureServiceOn();
            
            % relative path to the connector web base url
            relativeUrlPath = obj.RelativeUrl;
            
            % append the query string to the url if provided
            if nargin == 2 && ~isempty(queryString)
               if isempty(strfind(relativeUrlPath, '?'))
                   relativeUrlPath = sprintf('%s?', relativeUrlPath);
               else
                   relativeUrlPath = sprintf('%s&', relativeUrlPath);
               end
               relativeUrlPath = sprintf('%s%s', relativeUrlPath, queryString);
            end
            
            % create the absolute path to the web page URL and save the URL
            obj.AbsoluteUrlPath = connector.getUrl(relativeUrlPath);            
        end
    end        
end
