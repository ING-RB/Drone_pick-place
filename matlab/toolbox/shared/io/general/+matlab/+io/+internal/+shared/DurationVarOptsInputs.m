classdef DurationVarOptsInputs < matlab.io.internal.shared.DecimalSeparatorInput ...
        & matlab.io.internal.shared.InputFormatInput
    %DURATIONVAROPTSINPUTS
    
    %   Copyright 2018 The MathWorks, Inc.
    
    properties (Parameter)
        %DURATIONFORMAT
        %   Variables imported as duration will have this format.
        %
        %   See also matlab.io.DurationVariableImportOptions
        DurationFormat = 'default';% system default
        
        %FIELDSEPARATOR
        %   The character to be used to delimit the separation of fields in
        %   duration data.
        %
        %   See also matlab.io.DurationVariableImportOptions
        FieldSeparator = ':';
    end
    
    methods
        function obj = set.DurationFormat(obj,rhs)
            if ~strcmp(rhs,"default")
                try
                    duration(0,0,0,'Format',rhs);
                catch ME, throw(ME),
                end
            end
            obj.DurationFormat = convertStringsToChars(rhs);
        end
        
        function obj = set.FieldSeparator(obj,rhs)
            rhs = convertStringsToChars(rhs);
            if ~matlab.io.internal.validateScalarSeparator(rhs)
                error(message('MATLAB:textio:textio:InvalidFieldSep'))
            end
            obj.FieldSeparator = rhs;
        end
    end
    
    methods (Access = protected)
        function val = setFillValue(~,val)
            try
                val = duration(val);
                assert(isscalar(val));
            catch
                error(message('MATLAB:textio:io:FillValueType','duration'));
            end
        end
        
        function rhs = setType(obj,rhs)
            obj.validateFixedType(obj.Name,'duration',rhs);
        end
        
        function rhs = getType(~,~)
            rhs = 'duration';
        end
        
        function val = getFillValue(~,val)
            if isempty(val)
                val = seconds(NaN);
            end
        end
        
        function val = setInputFormat(~,val)
            try
                if strlength(val) > 0
                    duration('NaN','InputFormat',val);
                end
            catch ME, throw(ME),
            end
        end
    end
end

