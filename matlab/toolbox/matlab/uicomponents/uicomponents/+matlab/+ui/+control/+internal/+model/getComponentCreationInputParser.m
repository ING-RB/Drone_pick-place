function parserCopy = getComponentCreationInputParser(component)
%GETCOMPONENTCREATIONINPUTPARSER return appropriate parsser for
%the component class provided as input.

% Copyright 2017-2020 The MathWorks, Inc.

mlock; % keep variable in memory until MATLAB quits
persistent inputParsers;

if isempty(inputParsers)
    inputParsers = struct;
end

componentType = component;
% Get classname of component if it is an object
if ~ischar(component)
    componentType = class(component);
end
% Field names cannot contain '.'
% Use replace instead of genvarname for performance reasons
type = replace(componentType, '.', '_');

if isfield(inputParsers, type)
    parser = inputParsers.(type);
    
else
    % Get public properties of component
    parameterList = matlab.ui.control.internal.model.getComponentCreationPublicProperties(component);
    parser = inputParser;
    parser.KeepUnmatched = true;
    
    for index = 1:numel(parameterList)
        % Adding parameters makes partial matching in the
        % inputParser more robust
        parser.addParameter(parameterList{index},[], @(thisValue)true)
    end
    inputParsers.(type) = parser;
end

% Return a copy because calling parse on the object can update the Results
% property of the parser without it being obvious.  See g1809128. 
parserCopy = copy(parser);
end
