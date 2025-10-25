classdef NumericVarOptsInputs < matlab.io.internal.shared.DecimalSeparatorInput
    %NUMERICVAROPTSINPUTS Summary of this class goes here
    %   Detailed explanation goes here

%   Copyright 2018-2019 The MathWorks, Inc.
    
    properties (Parameter)
        %EXPONENTCHARACTER
        %   A character vector containing characters that are used as an
        %   exponent signifier for a number.
        %
        %   Example: if ExponentCharacter = 'a' then the text "1.2a3" will be
        %   imported the number 1200.
        %
        % See Also matlab.io.NumericVariableImportOptions
        ExponentCharacter = 'eEdD';
        
        %THOUSANDSSEPARATOR
        %   The character which is used to separate the thousands digit.
        %
        %   Example: if ThousandsSeparator=',' then the text "1,234,000" will be
        %   imported as the number 1234000.
        %
        % See Also matlab.io.NumericVariableImportOptions
        ThousandsSeparator = '';
        
        %TRIMNONNUMERIC
        %   A logical value that specifies that all prefixes and suffixes
        %   must be removed leaving only the numeric part.
        %
        % See Also matlab.io.NumericVariableImportOptions
        TrimNonNumeric = false;
         
        %NUMBERSYSTEM
        %   A character vector that denotes the number system used
        %   to read a number. Default is decimal.
        %
        %   Accepted values: decimal | hex | binary
        %
        % See Also matlab.io.NumericVariableImportOptions
        NumberSystem = 'decimal';
    end
    
    methods
        function obj = set.ExponentCharacter(obj,rhs)
        rhs = convertStringsToChars(rhs);
        if ~ischar(rhs) || ~isvector(rhs) || any(~ismember(lower(rhs),'a':'z'))
            error(message('MATLAB:textio:textio:InvalidExponent'))
        end
        obj.ExponentCharacter = rhs;
        end
        
        function obj = set.ThousandsSeparator(obj,rhs)
        rhs = convertStringsToChars(rhs);
        if ~isequal(rhs,'') && ~matlab.io.internal.validateScalarSeparator(rhs)
            error(message('MATLAB:textio:textio:InvalidThosandsSep'));
        end
        obj.ThousandsSeparator = rhs;
        end
        
        function obj = set.TrimNonNumeric(obj,rhs)
        try
            assert(isscalar(rhs) && ~isnan(rhs) && (islogical(rhs) || isnumeric(rhs)));
            obj.TrimNonNumeric = logical(rhs);
        catch
            error(message('MATLAB:textio:textio:InvalidTrimNonNumeric'));
        end
        end
        
        function obj = set.NumberSystem(obj,rhs)
        rhs = convertStringsToChars(rhs);
        if ~ischar(rhs) || ~isvector(rhs) || any(~ismember(lower(rhs),{'decimal','hex','binary'}))
            error(message('MATLAB:textio:textio:InvalidNumberSystem'))
        end
        obj.NumberSystem = rhs;
        end

    end
    methods (Access = protected)
        
        function val = setType(obj,val)
        import matlab.io.internal.supportedTypeNames
        val = convertCharsToStrings(val);
        if ~(isstring(val) && isscalar(val)) ...
                || ~any(strcmp(val,...
                {'double','single',...
                'int8','uint8',...
                'int16','uint16',...
                'int32','uint32',...
                'int64','uint64','auto'}))
            if any(strcmp(supportedTypeNames,val))
                newMsg = [getString(message('MATLAB:textio:io:NumericType')), ...
                    '\n\n',getString(message('MATLAB:textio:io:Setdatatype')), '\n', ...
                    getString(message('MATLAB:textio:io:SetvartypeSyntax',obj.Name,val))];
                throw(MException('MATLAB:textio:io:StaticOptionsType',newMsg));
            end
            error(message('MATLAB:textio:io:NumericType'));
        end
        val = char(val);
        end
        
        function val = getType(~,val)
        if isempty(val), val = 'double';end
        end
        
        function val = setFillValue(obj,val)
        try
            assert(isscalar(val)&&(isnumeric(val)||islogical(val)||ismissing(val)));
            if (obj.Type == "auto")
                cast(val,'uint64');
            else
                cast(val,obj.Type);
            end
        catch
            error(message('MATLAB:textio:io:FillValueType',obj.Type));
        end
        end
        
        function val = getFillValue(obj,val)
        if isempty(val) || ismissing(val)
            val = NaN;
        end
        if obj.Type == "auto" && isnan(obj.FillValue_)
            val = 0;
        elseif obj.Type == "auto" && ~isnan(obj.FillValue_)
            val = obj.FillValue_;
        else
            val = cast(val,obj.Type);
        end
        end
    end
end

