function callbackPropertyNames = extractCallbackPropertyNamesFromMetaClass(metaClass)
    %EXTRACTCALLBACKPROPERTYNAMESFROMMETACLASS

%   Copyright 2024 The MathWorks, Inc.

    % MATLAB's callback type
    callbackType = 'matlab.graphics.datatype.Callback';
    
    % Excluded Callbacks (callbacks we just decided to not show)
    excludedCallbackNames = {'ButtonDownFcn', 'CreateFcn', 'DeleteFcn'};

    % Find anything that is a Callback
    allTypes = {metaClass.PropertyList.Type};
    callbackIndices = cellfun(@(x) strcmp(x.Name, callbackType) , allTypes);
    
    % Find public propertes
    publicPropertiesIndices = strcmp({metaClass.PropertyList.GetAccess}, 'public');
    
    % Find Non Hidden
    %
    % Needed to exclude things like ValueChangedFcn_I
    nonHiddenPropertiesIndices = ~[metaClass.PropertyList.Hidden];
    
    % Find excluded Callbacks
    nonExcludedPropertiesIndices = ~ismember({metaClass.PropertyList.Name}, excludedCallbackNames);
    
    % Create overall indices List
    callbacksToShow = and(nonExcludedPropertiesIndices, and(callbackIndices, and(publicPropertiesIndices, nonHiddenPropertiesIndices)));
    
    callbackPropertyList = metaClass.PropertyList(callbacksToShow);
    callbackPropertyNames = {callbackPropertyList.Name};
end
