classdef RowNodeNameProvider < matlab.io.internal.FunctionInterface
%

% Copyright 2024 The MathWorks, Inc.

    properties (Parameter)
        %RowNodeName
        %    Node name which delineates rows of the output table.
        RowNodeName = string(missing);
    end

    methods
        function obj = set.RowNodeName(obj, rhs)
            if ~matlab.internal.datatypes.isScalarText(rhs, false)
                error(message("MATLAB:io:xml:detection:RowNodeNameUnsupportedType"));
            end

            rhs = convertCharsToStrings(rhs);

            obj.RowNodeName = rhs;
        end
    end
end
