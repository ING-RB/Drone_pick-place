classdef VariableConverter < handle
%

%   Copyright 2024 The MathWorks, Inc.

    properties
        % TODO: add property validation
        nodeVector
        counts
        valueTypes
        numberTypes
        stringTypes
        strings
        doubles
        int64s
        uint64s
        varOpts
        whitespace

        % Computed properties
        numValues
        numRows
        numColumns
        convertedData
        erroredConversions
    end

    methods
        function obj = VariableConverter(nodeVector, counts, varOpts, whitespace)
        %READER Construct an instance of this class
        %   This class keeps track of the marshaller's current state

            import matlab.io.json.internal.NodeVector;

            obj.varOpts = varOpts;
            obj.whitespace = whitespace;
            obj.counts = counts;

            obj.nodeVector = nodeVector;

            % Data directly from nodeVector
            obj.valueTypes = obj.nodeVector.Types;
            obj.numberTypes = obj.nodeVector.NumberTypes;
            obj.doubles = obj.nodeVector.Doubles;
            obj.uint64s = obj.nodeVector.Uint64s;
            obj.int64s = obj.nodeVector.Int64s;
            obj.strings = obj.nodeVector.Strings;

            % Dependent properties
            obj.numValues = sum(obj.counts);
            obj.numRows = length(obj.counts);
            obj.numColumns = max(obj.counts);
        end
    end
end
