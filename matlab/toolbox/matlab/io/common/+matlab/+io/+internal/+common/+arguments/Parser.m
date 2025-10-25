classdef Parser
%PARSER Object for parsing name-value pairs.

% Copyright 2023 The MathWorks, Inc.

    properties(GetAccess=public, SetAccess=private)
        NameValuePairs = dictionary(string.empty(1, 0), matlab.io.internal.common.arguments.NameValuePair.empty(1, 0))
    end

    properties(Dependent)
        NVPairNames
    end

    methods
        function obj = Parser(nvpairs)
            arguments
                nvpairs(1, :) NameValuePair = NameValuePair.empty(1, 0)
            end

            import matlab.io.internal.common.arguments.NameValuePair

            for ii = 1:numel(nvpairs)
                obj.NameValuePairs(nvpairs(ii).Name) = nvpairs(ii);
            end
        end

        function [results, supplied] = parse(obj, varargin)
            numinputs = numel(varargin);
            if mod(numinputs, 2) ~= 0
                error(message("MATLAB:io:common:arguments:OddNameValuePairs"));
            end

            [results, supplied] = obj.configureOutputStructs();
            for ii = 1:2:numinputs-1
                name = obj.findMatch(varargin{ii});
                results.(name) = obj.NameValuePairs(name).validate(varargin{ii+1});
                supplied.(name) = true;
            end
        end

        function names = get.NVPairNames(obj)
            names = obj.NameValuePairs.keys;
        end

        function name = findMatch(obj, name)
            if ~matlab.io.internal.common.validators.isScalarText(name)
                error(message("MATLAB:io:common:arguments:InvalidParameterType"));
            end

            names = obj.NVPairNames;
            indices = find(startsWith(names, name, IgnoreCase=true));

            if numel(indices) == 0
                error(message("MATLAB:io:common:arguments:UnknownParameter", name));
            elseif numel(indices) > 1
                error(message("MATLAB:io:common:arguments:AmbiguousParameter", name));
            else
                name = names(indices);
            end
        end

        function [results, supplied] = configureOutputStructs(obj)
            names = obj.NVPairNames;
            defaultValues = {obj.NameValuePairs.values.DefaultValue};
            results = cell2struct(defaultValues, names, 2);
            supplied = cell2struct(repmat({false}, [1 numel(names)]), names, 2);
        end
    end
end

