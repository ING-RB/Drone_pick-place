function [results,defaults] = parseGroupPropertyValues(varargin)
% Parse the name/value pairs associated with creating a group

%   Copyright 2015-2019 The MathWorks, Inc.
    
    optionalInput = varargin{1}(2:end);
    
    persistent groupPropValueParser;
    
    if(isempty(groupPropValueParser))
        groupPropValueParser = inputParser;
        % add optional Property-Value pairs to inputParser
        groupPropValueParser.addParameter('Hidden', false, ...
            @(v)(matlab.settings.internal.isValidInputForLogical(...
                v, 'Hidden')));
        groupPropValueParser.addParameter('ValidationFcn', ...
            function_handle.empty, ...
            @matlab.settings.internal.isValidFunctionHandle);   
    end
    
    groupPropValueParser.parse(optionalInput{:});
    
    results.Hidden = logical(groupPropValueParser.Results.Hidden);
    assert(isscalar(results.Hidden), message('MATLAB:settings:LogicalScalarHidden')); 
    
    results.Name = char(varargin{1}{1}); 
    matlab.settings.internal.isValidName(results.Name, 'SettingsGroup');
    
    results.ValidationFcn = groupPropValueParser.Results.ValidationFcn;
    
    defaults = cell2struct(cell([1 numel(fields(results))]),fieldnames(results),2);       
    def_fieldnames = groupPropValueParser.UsingDefaults;
    
    for i=1:numel(def_fieldnames)
        defaults.(def_fieldnames{i}) = true;
    end   
    
    idx = structfun(@(x)isempty(x),defaults);
    def_fieldnames = fieldnames(defaults);
    
    for i=1:numel(def_fieldnames)
        if(idx(i))
            defaults.(def_fieldnames{i}) = false;
        end
    end
end
