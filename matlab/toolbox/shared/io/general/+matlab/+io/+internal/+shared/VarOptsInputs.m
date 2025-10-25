classdef VarOptsInputs < matlab.io.internal.FunctionInterface ...
        & matlab.io.internal.shared.TreatAsMissingInput ...
        & matlab.io.internal.shared.CommonVarOpts
    %

    %   Copyright 2018-2019 The MathWorks, Inc.

    properties (Access = {?matlab.io.internal.shared.NumericVarOptsInputs,...
                          ?matlab.io.internal.functions.ReadMatrixWithImportOptions,...
                          ?matlab.io.VariableImportOptions,...
                          ?matlab.io.internal.functions.DetectImportOptions,...
                          ?matlab.io.internal.FastVarOpts,...
                          ?matlab.io.internal.builders.Builder})
        Name_ = '';
        Type_ = '';
        FillValue_;
    end

    properties (Parameter)
        %NAME
        %   Name of the variable to be imported. Must be a valid identifier.
        %
        % See also matlab.io.VariableImportOptions
        Name

        %TYPE
        %   The input type of the variable when imported.
        %
        % See also matlab.io.VariableImportOptions
        Type

        %FILLVALUE
        %   Used as a replacement value when ErrorRule = 'fill' or
        %   MissingRule = 'fill'. The valid types depend on the value of TYPE.
        %
        % See also matlab.io.VariableImportOptions
        %   matlab.io.spreadsheet.SpreadsheetImportOptions/MissingRule
        %   matlab.io.spreadsheet.SpreadsheetImportOptions/ImportErrorRule
        %   matlab.io.VariableImportOptions/Type
        FillValue
    end
    % get/set functions
    methods
        function obj = set.Name(obj,rhs)
            rhs = convertCharsToStrings(rhs);
            if ~(isstring(rhs) && isscalar(rhs))
                error(message('MATLAB:textio:textio:InvalidStringProperty','Name'));
            end

            % Make sure that the Variable Options name is non-empty and
            % not greater than namelengthmax.
            stringLength = strlength(rhs);
            if stringLength == 0 || stringLength > namelengthmax
                error(message('MATLAB:table:VariableNameNotValidIdentifier', rhs));
            end

            obj.Name_ = char(rhs); %#ok<MCSUP> 
        end

        function val = get.Name(opts)
            val = opts.Name_;
        end

        function obj = set.Type(obj,val)
            val = convertStringsToChars(val);
            obj.Type_ = setType(obj,val); %#ok<MCSUP> 
        end

        function val = get.Type(obj)
            val = getType(obj,obj.Type_);
        end

        function obj = set.FillValue(obj,val)
            obj.FillValue_ = setFillValue(obj,val); %#ok<MCSUP> 
        end

        function val = get.FillValue(obj)
        % Converts to the correct type
            val = getFillValue(obj,obj.FillValue_);
        end
    end

    methods (Hidden, Sealed)
        function opts = setNames(opts,names)
        % avoid validating names
            if ~isempty(names)
                ids = ~strcmp(names,{opts.Name_});
                for id = find(ids)
                    opts(id).Name_ = names{id};
                end
            end
        end

        function names = getNames(opts)
        % avoid validating names
            names = {opts.Name_};
        end
    end

    methods (Abstract,Access = protected)
        type = setType(obj,val);
        type = getType(obj,val);
        val = setFillValue(obj,val);
        val = getFillValue(obj,val);
    end

    methods (Static, Hidden)
        function validateFixedType(name,type,rhs)
            import matlab.io.internal.supportedTypeNames
            rhs = convertCharsToStrings(rhs);
        
            if ~isstring(rhs) 
                error(message('MATLAB:textio:io:NotDataType'));
            end

            if type == rhs
                % If the new Type value is the same as the old one, then
                % return early without throwing an error. This is necessary
                % for loadobj to work as expected because it calls set.Type
                % during the object initialization.
                return;
            end

            if ~any(strcmp(supportedTypeNames,rhs))
                error(message('MATLAB:textio:io:NotDataType'));
            end

            newMsg = [getString(message('MATLAB:textio:io:StaticOptionsType',type)), ...
                      '\n\n',getString(message('MATLAB:textio:io:Setdatatype')), '\n', ...
                      getString(message('MATLAB:textio:io:SetvartypeSyntax',name,rhs))];
            throw(MException('MATLAB:textio:io:StaticOptionsType',newMsg));
        end
    end
end
