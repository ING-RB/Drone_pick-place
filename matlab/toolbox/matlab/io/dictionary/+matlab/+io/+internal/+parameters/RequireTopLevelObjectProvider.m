classdef RequireTopLevelObjectProvider < matlab.io.internal.FunctionInterface
% REQUIRETOPLEVELOBJECTPROVIDER Class for RequireTopLevelObject option
% for reading JSON files, which sets whether the top level type of a 
% JSON file must be object type.

% Copyright 2024 The MathWorks, Inc.

    properties (Parameter, Hidden)
        %RequireTopLevelObject
        %    Error if top level JSON type is not JSON Object
        % TODO: consider expanding to "AcceptedTopLevelType" and accepting
        % an array of strings to represent accepted types.
        RequireTopLevelObject = true;
    end
    
    methods
        function func = set.RequireTopLevelObject(func, rhs)
            validateattributes(rhs, "logical", "scalar", "readdictionary", "RequireTopLevelObject");
            func.RequireTopLevelObject = logical(rhs);
        end
    end
end