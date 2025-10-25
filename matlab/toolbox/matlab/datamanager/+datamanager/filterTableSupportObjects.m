function [listObjects, tableSupportUsed] = filterTableSupportObjects(listObjects)

% This function is undocumented and may change in a future release.

% Utility method which takes in a list of objects in the axes and filters
% out objects which are using a table for data. It also returns a boolean
% flag to indicate if anything was filtered.

% Copyright 2021 The MathWorks, Inc.

% Iterate over all objects to see if they are using table for data.  
tableMask = false(numel(listObjects),1);
for i = 1:numel(listObjects)
    obj = listObjects(i);
    % See if object uses Table Support mixin
    if isa(obj, 'matlab.graphics.mixin.DataProperties')
        
        % Check to see if any of the data values from the existing channels
        % are coming from a table. 
        if obj.isDataComingFromDataSource("X") || ...
                obj.isDataComingFromDataSource("Y") || ...
                obj.isDataComingFromDataSource("Z") || ...
                obj.isDataComingFromDataSource("Color") || ...
                obj.isDataComingFromDataSource("Alpha") || ...
                obj.isDataComingFromDataSource("Size")
            tableMask(i) = true;
        end

    end
end

tableSupportUsed = any(tableMask);
listObjects(tableMask) = [];
