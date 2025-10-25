classdef CategoricalVarOptsInputs < matlab.io.internal.FunctionInterface
    %CATEGORICALVAROPTSINPUTS Summary of this class goes here
    %   Detailed explanation goes here

%   Copyright 2018 The MathWorks, Inc.
    
    properties (Parameter)
        %CATEGORIES
        %   The expected import categories. If an input field doesn't match one of
        %   the expected categories, then the conversion is an error.
        %
        % See Also matlab.io.CategoricalVariableImportOptions
        Categories = {};
        
        %PROTECTED
        %
        % See Also matlab.io.CategoricalVariableImportOptions
        Protected = false;
        
        %ORDINAL
        %
        % See Also matlab.io.CategoricalVariableImportOptions
        Ordinal = false;
    end
    
    methods
        function obj = set.Categories(obj,rhs)
        try
            rhs = matlab.io.internal.validators.validateCellStringInput(rhs, 'Categories');
            assert(ischar(rhs) || iscell(rhs));
        catch
            error(message('MATLAB:textio:textio:InvalidStringOrCellStringProperty','Categories'));
        end
        obj.Categories = rhs;
        end
        
        function obj = set.Protected(obj,rhs)
        try
            assert(isscalar(rhs))
            rhs = logical(rhs);
        catch
            error(message('MATLAB:textio:textio:ExpectedScalarLogical'));
        end
        if ~rhs && obj.Ordinal
            error(message('MATLAB:categorical:UnprotectedOrdinal'))
        end
        obj.Protected = rhs;
        end
        
        function obj = set.Ordinal(obj,rhs)
        try
            assert(isscalar(rhs))
            obj.Ordinal = logical(rhs);
        catch
            error(message('MATLAB:textio:textio:ExpectedScalarLogical'));
        end
        if obj.Ordinal
            obj.Protected = true;
        end
        end
    end
    methods (Access = protected)
        function val = setFillValue(obj,val)
        if ischar(val) || isstring(val)
            val = {convertStringsToChars(val)};
            isUndef = any(strcmp(val,{categorical.undefLabel,''}));
        else
            isUndef = ismissing(val);
        end
        
        if isUndef
            val = {''};
        end
        
        try  % The FillValue must be convertable to a categorical scalar.
            val = categorical(val);
            assert(isscalar(val));
        catch
            error(message('MATLAB:textio:io:FillValueType','categorical'));
        end
        
        if ~isempty(obj.Categories) && ~isUndef %#ok<*MCSUP>
            [~,id] = ismember(char(val),obj.Categories);
            if id == 0
                error(message('MATLAB:textio:io:FillValueCategorical',categorical.undefLabel));
            end
            val = obj.Categories{id}; % store FillValue as char array
        elseif isUndef
            val = '';
        else
            val = char(val);
        end
        end
        
        function val = getType(~,~)
        val = 'categorical';
        end
        function val = getFillValue(obj,val)
        if isempty(val)
            val = categorical(NaN);
        elseif isempty(obj.Categories)
            val = categorical({val});
        else
            % The fill value should have the same properties as the resulting
            % categorical array, or it should become undefined.
            [~,id] = ismember(char(val),obj.Categories);
            val = categorical(id,1:numel(obj.Categories),obj.Categories,...
                'Ordinal',obj.Ordinal,...
                'Protected',obj.Protected);
        end
        end
        
        function val = setType(obj,val)
        matlab.io.internal.shared.VarOptsInputs.validateFixedType(obj.Name,'categorical',val);
        end
    end
end

