classdef NameValueParser < robotics.core.internal.NameValueParserInterface
%This class is for internal use only. It may be removed in the future.

%NameValueParser Codegen-compatible name-value pair parser
%   MATLAB implementation of NameValueParserInterface that uses
%   inputParser. This class redirects to NameValueParserCodegen during
%   code generation.
%
%   NOTE: This internal class does not perform any validations.
%
%   Example:
%
%       % Create parameter name cell array
%       names = {'Parameter1', 'Parameter2'};
%
%       % Create default value cell array
%       defaults = {0, 'foo'};
%
%       % Create a parser
%       parser = robotics.core.internal.NameValueParser( ...
%                   names,defaults);
%
%       % Parse name-value inputs (where the name-value inputs are
%       % contained in varargin).
%       parse(parser, varargin{:});
%
%       % Access parameter values using the parameterValue method
%       p1value = parameterValue(parser, 'Parameter1');
%

%   Copyright 2016-2023 The MathWorks, Inc.

%#codegen

    properties (Access = private)

        %Parser - inputParser object
        Parser

    end

    methods

        function obj = NameValueParser(names, defaults)
        %NameValueParser Constructor
        %   Assumes that NAMES and DEFAULTS are cell arrays with
        %   the same number of elements and that each cell in NAMES
        %   contains a nonempty row vector of chars.
            obj = obj@robotics.core.internal.NameValueParserInterface(names, defaults);
            obj.Parser = inputParser();
            for i = 1:numel(obj.Names)
                obj.Parser.addParameter(obj.Names{i}, obj.Defaults{i});
            end
        end

        function parse(obj, varargin)
            parse(obj.Parser, varargin{:});
        end

        function value = parameterValue(obj, name)
        %parameterValue Return the VALUE for the parameter specified by NAME
        %   Note: You must call the PARSE method before calling this method
            value = obj.Parser.Results.(name);
        end

        function newobj = copy(obj)
            newobj = robotics.core.internal.NameValueParser(obj.Names, ...
                                                            obj.Defaults);
            newobj.Parser = copy(obj.Parser);
        end

    end

    methods (Access = private, Static)

        function name = matlabCodegenRedirect(~)
            name = 'robotics.core.internal.codegen.NameValueParser';
        end

    end

end
