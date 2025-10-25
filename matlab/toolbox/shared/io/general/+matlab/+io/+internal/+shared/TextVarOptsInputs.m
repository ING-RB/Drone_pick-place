classdef TextVarOptsInputs < matlab.io.internal.FunctionInterface
    %

%   Copyright 2018 The MathWorks, Inc.
    
    properties (Parameter)
        %WHITESPACERULE
        %   Rules for dealing with leading and trailing whitespace when importing
        %   text data.
        %   'trim' - (default) Any leading or trailing whitespace is removed from
        %            the text. Interior whitespace is unaffected.
        %
        %   'trimleading' - Only the leading whitespace will be removed.
        %
        %   'trimtrailing' - Only the trailing whitespace will be removed.
        %
        %   'preserve' - No whitespace will be removed.
        %
        %   See also matlab.io.TextVariableImportOptions
        WhitespaceRule = 'trim';
    end
    
    methods
        function obj = set.WhitespaceRule(obj,rhs)
        obj.WhitespaceRule = validatestring(rhs,...
            {'trim','trimleading','trimtrailing','preserve'});
        end
    end
    
    methods (Access = protected)
        function val = setFillValue(~,val)
        % Only accept cellstr with 1 char element.
        val = convertCharsToStrings(val);
        
        if ~(isstring(val) && isscalar(val))
            if isa(val,'missing') && isscalar(val)
                val = string(missing);
                return
            end
            error(message('MATLAB:textio:io:FillValueText'));
        end
        end
        
        function val = setType(obj,val)
        try
            val = validatestring(val,{'char','string'});
        catch ME
            import matlab.io.internal.supportedTypeNames
            if strcmp(ME.identifier,'MATLAB:unrecognizedStringChoice') && any(strcmp(supportedTypeNames,val))
                % additional information to help with debugging
                newMsg = ['\n\n',getString(message('MATLAB:textio:io:Setdatatype')), '\n', ...
                    getString(message('MATLAB:textio:io:SetvartypeSyntax',obj.Name,val))];
                throw(MException('MATLAB:unrecognizedStringChoice',[ME.message, newMsg]));
            end
            throw(ME);
        end
        end
        
        function val = getType(~,val)
        if isempty(val), val = 'char';end
        end
        
        function val = getFillValue(obj,val)
        if isnumeric(val) % default []
            switch obj.Type
                case 'char'
                    val = '';
                case 'string'
                    val = string(missing);
            end
        else
            switch obj.Type
                case 'char'
                    val = convertStringsToChars(val);
                case 'string'
                    val = convertCharsToStrings(val);
            end
        end
        end
    end
end

