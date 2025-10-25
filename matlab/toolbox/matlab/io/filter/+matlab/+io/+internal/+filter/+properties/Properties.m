classdef (Abstract) Properties < matlab.mixin.Scalar
%Properties    Superclass for RowFilter Properties objects.
%
%   See also: rowfilter

%   Copyright 2021 The MathWorks, Inc.

    methods (Abstract)
        varNames = getVariableNames(props);
        props = replaceVariableNames(props, oldVariableNames, newVariableNames);
    end

    properties (Dependent, SetAccess=protected)
        VariableNames (1, :) string {mustBeNonmissing}
    end

    methods
        function varNames = get.VariableNames(props)
            % Yes, the natural way to do this would just be to make
            % VariableNames abstract and then customize it as
            % concrete/dependent in each Properties subclass.
            %
            % But there's a limitation with dependent properties which
            % means that this approach won't work.
            %
            % See: https://www.mathworks.com/help/matlab/matlab_oop/property-access-methods.html
            % specifically, the section about "MATLAB does not call access
            % methods recursively."
            %
            % This means that a nested Properties object will not call the
            % getter of dependent VariableNames on the inner Properties object
            % correctly.
            varNames = getVariableNames(props);
        end
    end
end
