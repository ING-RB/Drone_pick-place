classdef NameValueProviderLiaison < handle
    % This class is undocumented and will change in a future release.

    % NameValueProviderLiaison - Class to handle communication between NameValueProviderServices.
    %
    % See Also: NameValueProviderService, Service, ServiceLocator, ServiceFactory

    % Copyright 2018-2022 The MathWorks, Inc.

    properties(SetAccess=immutable)
        Parser (1,1) inputParser;
    end
    
    properties(GetAccess=private, SetAccess=immutable)
        ResolveMap
    end
    
    properties(Dependent, SetAccess=immutable)
        Results;
        UsingDefaults;
        Unmatched;
    end
    
    methods
        function liaison = NameValueProviderLiaison(parser)
            liaison.ResolveMap = containers.Map;
            liaison.Parser = parser;
        end
        
        function addParameter(liaison,paramName,defaultValue,validateFcn,resolveFcn)
            liaison.Parser.addParameter(paramName,defaultValue,validateFcn);
            if nargin > 4
                liaison.ResolveMap(paramName) = resolveFcn;
            end
        end
        
        function parse(liaison,varargin)
            liaison.Parser.parse(varargin{:});
        end
        
        function results = get.Results(liaison)
            results = liaison.Parser.Results;
            
            % Resolve the specified values if needed:
            allParams = string(liaison.Parser.Parameters);
            suppliedParams = setdiff(allParams,string(liaison.Parser.UsingDefaults));
            paramsToResolve = intersect(suppliedParams,string(liaison.ResolveMap.keys));
            for paramName = reshape(paramsToResolve,1,[])
                resolveFcn = liaison.ResolveMap(paramName);
                results.(paramName) = resolveFcn(results.(paramName));
            end
        end

        function defaults = get.UsingDefaults(liaison)
            defaults = liaison.Parser.UsingDefaults;
        end

        function results = get.Unmatched(liaison)
            results = liaison.Parser.Unmatched;
        end
    end
end
