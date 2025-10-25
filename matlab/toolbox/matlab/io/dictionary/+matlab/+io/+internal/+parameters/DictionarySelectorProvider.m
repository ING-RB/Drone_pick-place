classdef DictionarySelectorProvider < matlab.io.internal.FunctionInterface
% DICTIONARYSELECTORPROVIDER An interface for functions that accept a DICTIONARYSELECTOR

% Copyright 2024 The MathWorks, Inc.

    properties (Parameter)
        DictionarySelector = "";
    end

    methods
        function obj = set.DictionarySelector(obj, rhs)
            validateattributes(rhs,["string", "char"], "scalartext", ...
                 "readdictionary","DictionarySelector");
            obj.DictionarySelector = rhs;
        end
    end
end