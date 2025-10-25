function [siblingProperties, modeProperties] = getPropertiesWithMode(objectClassName, propertyValuesStruct, includeHiddenProperty)
% Given a struct of property names, property values... returns
% a list of properties that have a corresponding mode property
% on the object (whether it is in the propertyValuesStruct or not)
% Also returns the mode properties themselves
%
% Ex:
%
%   s.MajorTicks = 1:10;
%   s.MajorTicksMode = 'manual';
%   s.MinorTicks = 1:5:10;
%   s.Limits = [0, 10];
%
% getPropertiesWithMode(s) will return the following:
%
%   propertiesWithMode = {'MajorTicks', 'MinorTicks'};
%   modeProperties = {'MajorTicksMode', 'MinorTicksMode'};
%
% Because 'MajorTicks' and 'MinorTicks' have a corresponding
% mode property on the model itself

% Gather all properties on the object
mc = meta.class.fromName(objectClassName);
objectPropertyNames = {mc.PropertyList.Name};

% Array for the properties in propertyValuesStruct that have a mode
% property
siblingProperties = {};
% Array for the mode properties
modeProperties = {};

propertyNamesToIntrospect = fieldnames(propertyValuesStruct);

for idx = 1:length(propertyNamesToIntrospect)
    % Property of the structure, e.g. MajorTicks
    propertyName = propertyNamesToIntrospect{idx};

    % Corresponding mode property if there was one
    modePropertyName = strcat(propertyName, 'Mode');

    % Find the meta prop
    modeMetaProperty = mc.PropertyList(strcmp(modePropertyName, objectPropertyNames));

    % We want to include the property as a valid mode if and
    % only if:
    %
    % - It exists (obviously)
    %
    % - It is not Hidden and is part of the public API
    %   HG Object use backing Mode properties for every
    %   property, regardless if the XXXMode property is part of
    %   the public API.
    %
    %   Things like property edits and code generation, they
    %   are only concerned with Modes related to the public
    %   API.
    isValidModeProperty = ...
        ... % Property Exists
        ~isempty(modeMetaProperty) && ...
        ... % Property is not Hidden
        (includeHiddenProperty || (~includeHiddenProperty && ~modeMetaProperty.Hidden));

    if(isValidModeProperty)
        % The mode property does exist on the object
        siblingProperties{end+1} = propertyName;  %#ok<AGROW>
        modeProperties{end+1} = modePropertyName; %#ok<AGROW>
    end
end
end