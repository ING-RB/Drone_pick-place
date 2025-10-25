function names = getNestedFieldnames(currentStruct, baseString)
%This function is for internal use only. It may be removed in the future.

%getNestedFieldnames Returns a cell of names from a given struct. This
%   function can be used to extract field names of a ROS or ROS 2 message.
%   For example: given a struct a = struct('num',3,'name','ROS2');
%   >> ros.internal.utilities.getNestedFieldnames(a,'') will return a cell
%   array containing {'name'} {'num'}
%   Note that the order of fields depends on the recursive calling order.

%   Copyright 2023 The MathWorks, Inc.

    nameContainer = {};
    % Get all field names in current layer
    fs = fieldnames(currentStruct);
    fslen = length(fs);
    for i=1:fslen
        % Append prefix if there is any
        if isempty(baseString)
            newString = fs{i};
        else
            newString = [baseString '.' fs{i}];
        end

        nextLayer = currentStruct.(fs{i});
        if isstruct(nextLayer)
            % Nested messages, recursively calling this function
            nestedNames = getNestedFieldnames(nextLayer, newString);
            allNames = {nameContainer,nestedNames};
            nameContainer = cat(2,allNames{:});
        else
            % nextLayer is the actual value if it is not a structure
            % save newString into nameSubset
            nameContainer{end+1} = newString; %#ok<AGROW>
        end
    end
    names = unique(nameContainer);
end