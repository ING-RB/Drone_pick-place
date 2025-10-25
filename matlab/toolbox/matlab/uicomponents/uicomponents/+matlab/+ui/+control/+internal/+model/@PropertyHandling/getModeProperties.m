function [autoModeProperties, siblingAutoProperties, manualModeProperties, siblingManualProperties] = getModeProperties(propertyValuesStruct)
% Given a struct of property names, property values... returns
% a list of mode properties and their corresponding sibling
% properties
%
% Ex:
%
%   s.Foo = 1;
%   s.FooMode = 'auto';
%   s.Bar = 2;
%   s.Baz = 3;
%   s.BazMode = 'manual';
%
% getModeProperties(s) will return the following:
%
%   autoModeProperties = {'FooMode'}
%   siblingAutoProperties = {'Foo'}
%   manualModeProperties = {'BazMode'}
%   siblingManualProperties = {'Baz'}
%
% Beacuse the 'Bar' property did not have a mode, it is ignored

propertyNames = fieldnames(propertyValuesStruct);

% Finds all properties ending in 'Mode'
cellArrayOfIndices = regexp(propertyNames, 'Mode$');
modePropertyIndices = cellfun(@(x) ~isempty(x), cellArrayOfIndices);
modePropertyNames = propertyNames(modePropertyIndices);

% Preassign values for the auto / manual things that will be
% calculated
autoModeProperties = {};
siblingAutoProperties = {};
manualModeProperties = {};
siblingManualProperties = {};

for idx = 1:length(modePropertyNames)
    % Ex: XLimMode
    modePropertyName = modePropertyNames{idx};

    % Ex: XLim
    siblingPropertyName = modePropertyName(1 : end - 4);

    % Determine if the value is currently auto
    isAuto = strcmp(propertyValuesStruct.(modePropertyName), 'auto');

    if(isAuto)
        % Add to the autos
        autoModeProperties{end+1} = modePropertyName;
        siblingAutoProperties{end+1} = siblingPropertyName;
    else
        % Add to the manuals
        manualModeProperties{end+1} = modePropertyName;
        siblingManualProperties{end+1} = siblingPropertyName;
    end
end
end