classdef AttributeSuffixProvider < matlab.io.internal.FunctionInterface
%

% Copyright 2020 The MathWorks, Inc.

    properties (Parameter)
        %AttributeSuffix
        %    Suffix to append to all output table variable names corresponding
        %    to attributes from the XML file. Defaults to 'Attribute'.
        AttributeSuffix(1, :) = "Attribute"
    end

    methods
        function obj = set.AttributeSuffix(obj, rhs)
            if ~matlab.internal.datatypes.isScalarText(rhs, true)
                error(message("MATLAB:io:xml:readstruct:UnsupportedAttributeSuffixType"));
            end

            % Restrict AttributeSuffix to be at most 63-1 chars, since going over that
            % would overflow namelengthmax and lead to an invalid table variable.
            if strlength(rhs) >= namelengthmax
                error(message("MATLAB:io:xml:readstruct:AttributeSuffixTooLong"));
            end
            
            obj.AttributeSuffix = convertCharsToStrings(rhs);
        end
    end
end
