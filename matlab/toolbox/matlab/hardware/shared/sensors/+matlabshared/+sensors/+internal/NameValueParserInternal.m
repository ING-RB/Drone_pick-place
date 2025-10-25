classdef NameValueParserInternal < matlab.System
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
    %       parser = matlabshared.sensors.internal.NameValueParserInternal( ...
    %                   names,defaults);
    %
    %       % Parse name-value inputs (where the name-value inputs are
    %       % contained in varargin).
    %       parse(parser, varargin{:});
    %
    %       % Access parameter values using the parameterValue method
    %       p1value = parameterValue(parser, 'Parameter1');
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    
    %#codegen
    
    properties (Access = private,Nontunable)
        %Parser - inputParser object
        Parser
        
        % Name of the parameter
        Names
        
        % Default values for the parameter
        Defaults
        
        %Parameters - Struct for use in coder.internal.parseParameterInputs
        Parameters
        
        %ParsedResults - Cell-array of parsed values
        %   These are stored in the same order as Names and Defaults
        ParsedResults
        
        %NameToIndex - Struct for mapping names to indices of Defaults
        NameToIndex
    end
    
    methods
        
        function obj = NameValueParserInternal(names, defaults, varargin)
            %NameValueParser Constructor
            %   Assumes that NAMES and DEFAULTS are cell arrays with
            %   the same number of elements and that each cell in NAMES
            %   contains a nonempty row vector of chars.
            obj.Names = names;
            obj.Defaults = defaults;
            if coder.target('MATLAB')
                obj.Parser = inputParser();              
                p = inputParser;
                p.CaseSensitive = 0;
                p.PartialMatching = 1;
                if nargin>2
                        p.KeepUnmatched = varargin{1};
                end
                for i = 1:numel(names)
                    obj.Parser.addParameter(names{i}, defaults{i});
                end
            else
                for i = 1:numel(names)
                    parameters.(names{i}) = uint32(0);
                    nameToIndex.(names{i}) = i;
                end
                obj.Parameters = parameters;
                obj.NameToIndex = nameToIndex;
            end
        end
        
        function parse(obj, varargin)
            if coder.target('MATLAB')
                parse(obj.Parser, varargin{:});
            else
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
        end
        
        function value = parameterValue(obj, name)
            %parameterValue Return the VALUE for the parameter specified by NAME
            %   Note: You must call the PARSE method before calling this method
             if coder.target('MATLAB')
                value = obj.Parser.Results.(name);
             else
                  value = obj.ParsedResults{obj.NameToIndex.(name)};
             end
        end
        
        function unMatchedParameter  = unMatchedParamater(obj)
            if coder.target('MATLAB')
                fields = fieldnames(obj.Parser.Unmatched);
                fieldValues = struct2cell(obj.Parser.Unmatched);
                num = numel(fields)+numel(fieldValues);
                k = 1;       
                for i = 1:1:num/2
                        params{k} =  fields{i};
                        k = k+1;
                        params{k} =  fieldValues{i};
                        k = k+1;
                end
                     unMatchedParameter  = params;
            else
                   % not supported for codegen
                   unMatchedParameter  = {};
             end
        end
    end
end