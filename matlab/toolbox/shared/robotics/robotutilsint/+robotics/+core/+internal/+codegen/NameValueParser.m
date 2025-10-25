classdef NameValueParser < robotics.core.internal.NameValueParserInterface
%This class is for internal use only. It may be removed in the future.

%NameValueParser Codegen only name-value parser
%   Do not use this class directly, as it does not support MATLAB
%   execution. Rather, use NameValueParser, which redirects to this
%   class during code generation.

%   Copyright 2016-2023 The MathWorks, Inc.

%#codegen

    properties (Access = private)

        %Parameters - Struct for use in coder.internal.parseParameterInputs
        Parameters

        %ParsedResults - Cell-array of parsed values
        %   These are stored in the same order as Names and Defaults
        ParsedResults

        %NameToIndex - Struct for mapping names to indices of Defaults
        NameToIndex

    end

    methods

        function obj = NameValueParser(names, defaults)
        %NameValueParser Constructor
            obj = obj@robotics.core.internal.NameValueParserInterface( ...
                names, defaults);
            for i = 1:numel(names)
                parameters.(names{i}) = uint32(0);
                nameToIndex.(names{i}) = i;
            end
            obj.Parameters = parameters;
            obj.NameToIndex = nameToIndex;
        end

        function parse(obj, varargin)
            pstruct = coder.internal.parseParameterInputs( ...
                obj.Parameters, ...
                struct('PartialMatching','unique'), ...
                varargin{:});
            parsedResults = cell(size(obj.Names));
            for i = 1:numel(obj.Names)
                parsedResults{i} = ...
                    coder.internal.getParameterValue(pstruct.(obj.Names{i}), ...
                                                     obj.Defaults{i}, ...
                                                     varargin{:});
            end
            obj.ParsedResults = parsedResults;
        end

        function value = parameterValue(obj, name)
        %parameterValue Return the VALUE for the parameter specified by NAME
        %   Note: You must call the PARSE method before calling this method
            value = obj.ParsedResults{obj.NameToIndex.(name)};
        end

        function newobj = copy(obj)
            newobj = robotics.core.internal.codegen.NameValueParser(obj.Names, ...
                                                                    obj.Defaults);
            newobj.ParsedResults = obj.ParsedResults;
        end

    end

    methods(Static, Hidden)

        function props = matlabCodegenNontunableProperties(~)
        % Let the coder know about non-tunable parameters
            props = {'Parameters','NameToIndex'};
        end

    end

end
