classdef Reader < handle ...
        & matlab.mixin.Copyable
%

%   Copyright 2024 The MathWorks, Inc.

    properties
        % TODO: add property validation
        reader
        keys
        valueTypes
        numberTypes
        stringTypes = []
        doubles
        uint64s
        int64s
        strings
        numValues
        cumulativeRemoved
        opts
        parent
    end

    methods
        function obj = Reader(filename, opts)
        %READER Construct an instance of this class
        %   This class keeps track of the reader's current state

            import matlab.io.json.internal.LevelReader.*

            obj.reader = makeLevelReaderFromFile(filename, opts);

            obj.opts = opts;

            setReaderData(obj);
        end

        function setReaderData(obj)
            import matlab.io.json.internal.LevelReader.*

            [k, vT, d, s, nT, u64, i64] = listKeyValueData(obj.reader);
            obj.keys = k;
            obj.valueTypes = matlab.io.json.internal.read.JSONType(vT);
            obj.numberTypes = matlab.io.json.internal.read.NumericType(nT);
            obj.doubles = d;
            obj.uint64s = u64;
            obj.int64s = i64;
            obj.strings = s;
            % TODO: dependent property on valueTypes
            obj.numValues = length(obj.valueTypes);
            obj.cumulativeRemoved = zeros(obj.numValues, 1);

            % Set keys according to duplicateKeyRule
            obj.setKeys();
        end
    end
end
