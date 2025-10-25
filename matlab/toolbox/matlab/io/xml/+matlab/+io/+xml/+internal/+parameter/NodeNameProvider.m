classdef NodeNameProvider < matlab.io.internal.FunctionInterface
%

% Copyright 2020-2024 The MathWorks, Inc.

    properties (Parameter)
        %TableNodeName
        %    Name of the node which contains table data. If multiple nodes
        %    have the same name, READTABLE uses the first node with that name.
        TableNodeName = string(missing);

        %VariableNodeNames
        %    Node names which will be treated as variables of the output table.
        VariableNodeNames = string(missing);
    end

    methods
        function obj = set.TableNodeName(obj, rhs)
            if ~matlab.internal.datatypes.isScalarText(rhs, false)
                error(message("MATLAB:io:xml:detection:TableNodeNameUnsupportedType"));
            end

            rhs = convertCharsToStrings(rhs);

            obj.TableNodeName = rhs;
        end

        function obj = set.VariableNodeNames(obj, rhs)
            % matlab.internal.datatypes.isText does not check for empty cell
            % arrays, so we check for them explicitly here.
            isEmptyCell = isempty(rhs) && iscell(rhs);
            if ~matlab.internal.datatypes.isText(rhs, false, false) || isEmptyCell
                error(message("MATLAB:io:xml:detection:VariableNodeNamesUnsupportedType"));
            end

            rhs = convertCharsToStrings(rhs);

            obj.VariableNodeNames = rhs;
        end
    end
end
