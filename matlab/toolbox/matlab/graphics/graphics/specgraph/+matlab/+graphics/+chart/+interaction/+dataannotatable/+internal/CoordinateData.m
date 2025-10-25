classdef CoordinateData < handle
    % This class provides information about object's data tip content. All its
    % properties are read-only.
    
    %   Copyright 2018 The MathWorks, Inc.    
    properties(GetAccess = public, SetAccess = private)
        Source = ''; % An array representing the value source of the data tip (this may be empty).
        Value = []; % A string representing the value of the data tip (this may be empty).
    end
    
    methods
        function hObj = CoordinateData(source, value)
            % Construct the object.
            
            % Make sure the inputs are valid
            narginchk(2,2);
           
            hObj.Source = source;
            hObj.Value = value;
        end        
    end    
end