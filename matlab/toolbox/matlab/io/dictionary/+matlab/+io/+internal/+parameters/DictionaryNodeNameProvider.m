classdef DictionaryNodeNameProvider < matlab.io.internal.FunctionInterface
% DICTIONARYNODENAMEPROVIDER An interface for functions that accept a DICTIONARYNODENAME

% Copyright 2024 The MathWorks, Inc.

    properties (Parameter)
        %DictionaryNodeName
        %    Name of node underneath which readdictionary should
        %    start reading a dictionary.
        DictionaryNodeName = missing;
    end

    methods
        function obj = set.DictionaryNodeName(obj, rhs)
           validateattributes(rhs,["string", "char"],"scalartext", ...
                 "readdictionary","DictionaryNodeName");
            obj.DictionaryNodeName = string(rhs);
        end
    end
end