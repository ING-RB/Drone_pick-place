function [results,defaults] = parseSettingPropertyValues(varargin)
% Parse the name/value pairs associated with creating a setting

%   Copyright 2015-2021 The MathWorks, Inc.

    optionalInput = varargin{1}(2:end);

    persistent settingPropValueParser;
    if(isempty(settingPropValueParser))
        settingPropValueParser = inputParser;
        % add optional Property-Value pairs to inputParser
        settingPropValueParser.addParameter('Hidden', false, ...
            @(v)(matlab.settings.internal.isValidInputForLogical(...
                v, 'Hidden')));
        settingPropValueParser.addParameter('ReadOnly', false, ...
            @(v)(matlab.settings.internal.isValidInputForLogical(...
                v, 'ReadOnly')));
        settingPropValueParser.addParameter('PersonalValue',[]);
        settingPropValueParser.addParameter('InstallationValue',[]);
        settingPropValueParser.addParameter('ValidationFcn', ...
            function_handle.empty, ...
            @matlab.settings.internal.isValidFunctionHandle); 
        % A common potential mistake would be trying to specify the factory
        % value for a custom setting.
        settingPropValueParser.addParameter('FactoryValue', '', ...
            @noFactoryValueInCustomSetting);
    end
 
    settingPropValueParser.parse(optionalInput{:});
    
    results.Hidden = logical(settingPropValueParser.Results.Hidden);
    assert(isscalar(results.Hidden), message('MATLAB:settings:LogicalScalarHidden'));
    
    results.ReadOnly = logical(settingPropValueParser.Results.ReadOnly);
    assert(isscalar(results.ReadOnly), message('MATLAB:settings:LogicalScalarReadOnly'));
    
    results.Name = char(varargin{1}{1});
    matlab.settings.internal.isValidName(results.Name, 'Setting');
    
    results.PersonalValue = settingPropValueParser.Results.PersonalValue;
    results.InstallationValue = settingPropValueParser.Results.InstallationValue;
    results.ValidationFcn = settingPropValueParser.Results.ValidationFcn;
    
    defaults = cell2struct(cell([1 numel(fields(results))]),fieldnames(results),2);
    def_fieldnames = settingPropValueParser.UsingDefaults;
    
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

    % If ReadOnly is set to true, then PersonalValue or InstallationValue must be specified. If
    % not, throw an error
    if(results.ReadOnly && ... 
       (sum(arrayfun(@(x)strcmp(x,'PersonalValue'),settingPropValueParser.UsingDefaults)) == 1) && ...
       (sum(arrayfun(@(x)strcmp(x,'InstallationValue'),settingPropValueParser.UsingDefaults)) == 1))
        error(message('MATLAB:settings:config:ReadOnlySettingMustSpecifyPersonalValue',results.Name));
    end
end

function out = noFactoryValueInCustomSetting(~)    
    error(message('MATLAB:settings:config:SpecifyingFactoryValueNotSupportedForCustomSettings'));
    out = false;
end
