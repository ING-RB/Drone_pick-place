% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides functionality for creating a representation of a variable
% which may be too large to import before the import window opens.

% Copyright 2020 The MathWorks, Inc.

classdef ImportVariableSummary < handle
    properties
        Dimensions double = [1,1];
        Class char = 'double';
    end
    
    methods
        function s = size(this)
            % Returns the size of the summary variable
            
            arguments
                this matlab.internal.importdata.ImportVariableSummary;
            end
            
            s = this.Dimensions;
        end
        
        function c = class(this)
            % Returns the class of the summary variable
            
            arguments
                this matlab.internal.importdata.ImportVariableSummary;
            end

            c = this.Class;
        end
    end
end