classdef TabularType < coder.type.Base
    % Base type for TableType, TimetableType, and RegularTimetableType
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    methods (Static, Hidden)
        function c = constant()
            c.VariableNames = 'Properties.VariableNames';
            c.DimensionNames = 'Properties.DimensionNames';
        end
        
        function resize = supportsCoderResize()
            resize.supported = true;
            resize.callback = @matlab.coder.type.TabularType.resize;
        end
 
        function customtype = resize(customtype, ~, ~, ~)
            % Save the Size and VarDims, as these properties of customtype
            % will get reinitialize to default values
            sz = customtype.Size;
            vd = customtype.VarDims;
            % Resize the underlying coder type
            codertype = coder.resize(getCoderType(customtype), sz, vd);
            % Set rowDim.length to either a constant or a double scalar
            % type depending on whether the number of table rows is
            % constant
            if vd(1)
                codertype.Properties.rowDim.Properties.length = coder.newtype(...
                    'double',[1 1],[false false]);
            else
                codertype.Properties.rowDim.Properties.length = coder.Constant(sz(1));
            end

            % Bypass validation
            customtype = setCoderType(customtype, codertype, false);
            customtype = customtype.initFromCoderType(codertype);

            % setCoderType reinitialize customtype and Size and VarDims get
            % reset. Set them back to the resized values.
            customtype.Size = sz;
            customtype.VarDims = vd;
        end

        function x = validateDescription(x,access)
            % do not validate when access is nonempty: type.Description.xxx = yyy
            if matlab.internal.coder.type.util.isFullAssignment(access)
                if isa(x, 'coder.Constant')
                    val = x.Value;
                else
                    val = x;
                end
                if ~matlab.internal.coder.type.util.isCharRowType(val)
                    error(message('MATLAB:table:InvalidDescriptionType'));
                end
            end
        end
        
        function x = validateDimensionNames(x, access)
            % Nonconstant value and nonempty access are not supported for
            % constant properties. Do not check for errors in those cases,
            % and let them error later.
            if isa(x, 'coder.Constant') && matlab.internal.coder.type.util.isFullAssignment(access)
                val = x.Value;
                if ~iscellstr(val) || ~isrow(val) || numel(val) ~= 2 || ...
                        isempty(val{1}) || isempty(val{2}) %#ok<ISCLSTR>
                    error(message('MATLAB:table:InvalidDimNamesType'));
                end
            end
        end
    end

    methods (Access=protected, Hidden)
        function customtype = initialize(customtype)
            function applyDefaultSize()
                customtype.Size = [codertype.Properties.rowDim.Properties.length.Value ...
                                   codertype.Properties.data.SizeVector(2)];
            end

            codertype = getCoderType(customtype);
            % rowDim.length should always be constant during type
            % initialization. If the table has embedded types, prefer their
            % size usage over the outer container height (g2548367)
            % Do not apply for empty tables
            if ~isempty(codertype.Properties.data.Cells)
                try
                    % If the nested types are custom coder type, (not
                    % supported today), the catch will swallow the access
                    % to SizeVector and fallback to legacy, shipping behavior
                    sz = codertype.Properties.data.Cells{1}.SizeVector;

                    for c=2:numel(codertype.Properties.data.Cells)
                        % SizeVector isn't entirely accurate for aggregate
                        % types like datetime, categorical, etc so this is
                        % too heavy handed of a check
                        if ~isa(codertype.Properties.data.Cells{c}, 'coder.PrimitiveType') || codertype.Properties.data.Cells{c}.SizeVector(1) ~= sz(1)
                            throw false;
                        end
                    end
                catch
                    applyDefaultSize();
                    return;
                end

                % There are instances where the nested type won't
                % accurately mirror the height() of the table (a
                % Categorical ClassType representin ga 3x1 codes property
                % is such a type). Since the class type size vector can
                % underrepresent such cases, take the max value between the
                % computed nested coder type sizes and the previously
                % computed value in coder.typeof
                rows = max(sz(1), codertype.Properties.rowDim.Properties.length.Value);

                codertype.Properties.rowDim.Properties.length = coder.Constant(rows);
                customtype = setCoderType(customtype, codertype, false);
                customtype.Size = [rows codertype.Properties.data.SizeVector(2)];
            else
                applyDefaultSize();
            end
        end
    end

    methods (Access = public, Hidden = true)
        function obj = union(obj, type2)
            % We cannot call into typeof if we already have a type as
            % typeof will rely on the union op
            if ~isa(type2, 'coder.type.Base') && ~isa(type2, 'coder.Type')
                type2 = coder.typeof(type2);
            end
            
            if isa(type2, 'coder.type.Base')
                type2 = type2.getCoderType(false);
            end
            
            % Flatten constants as needed. To correctly union the backing
            % coder.ClassTypes, length must not be a constant as constants
            % with different values cannot be unioned (i.e. without losing
            % the constness of length, a 1x3 table type could not be
            % unioned with a 3x1 table type as length would be a different
            % constant value for each type)
            coderType = obj.getCoderType(false);
            
            istype2tabular = strcmp(type2.ClassName, 'table') || strcmp(type2.ClassName, 'timetable');
            % error if inputs don't have the same width
            if istype2tabular && (obj.Size(2) ~= length(type2.Properties.data.Cells))
                error(message('MATLAB:table:IncompatibleTableTypeWidth'));
            end
            
            if isa(coderType.Properties.rowDim.Properties.length, 'coder.Constant')
                length1 = coderType.Properties.rowDim.Properties.length.Value;
                coderType.Properties.rowDim.Properties.length = coder.typeof(coderType.Properties.rowDim.Properties.length.Value);
            else
                length1 = Inf;
            end
            
            if istype2tabular && isa(type2.Properties.rowDim.Properties.length, 'coder.Constant')
                length2 = type2.Properties.rowDim.Properties.length.Value;
                type2.Properties.rowDim.Properties.length = coder.typeof(type2.Properties.rowDim.Properties.length.Value);
            else
                length2 = Inf;
            end
            
            obj = obj.setCoderType(coderType, false);
            obj = obj.initializeProperties();
            function type = reinitializeLength(type)
                len = max(length1, length2);
                
                if isinf(len)
                    typeVal = coder.newtype('double',[1 1],[false false]);
                else
                    typeVal = coder.Constant(len);
                end
                type.Properties.rowDim.Properties.length = typeVal;
            end
            
            % Reinitialize table size from unioned type
            obj = union@coder.type.Base(obj, type2, @reinitializeLength);
            newSz = max(length1, length2);
            obj.Size = [newSz coderType.Properties.data.SizeVector(2)];
            obj.VarDims = [(length1 ~= length2) (coderType.Properties.data.SizeVector(2) ~= type2.Properties.data.SizeVector(2))];
        end
        
        function x = validateData(obj,x,access)
            if isa(x, 'coder.Constant')
                val = x.Value;
            elseif isa(x, 'coder.type.Base')
                val = x.getCoderType();
            else
                val = x;
            end
            nrows = obj.Size(1);
            nvars = obj.Size(2);
            varnrows = obj.VarDims(1);
            if ~matlab.internal.coder.type.util.isFullAssignment(access)
                valid = true;
                if numel(access) == 2 && isequal({access.type}, {'.', '{}'}) && ...
                        strcmp(access(1).subs, 'Cells')
                    % assigning individual cell
                    if isa(val, 'coder.Type')
                        if strcmp(val.ClassName, 'datetime')
                            isCorrectLength = (val.Properties.data.SizeVector(1) == nrows) && ...
                                (val.Properties.data.VariableDims(1) == varnrows);
                        elseif strcmp(val.ClassName, 'duration')
                            isCorrectLength = (val.Properties.millis.SizeVector(1) == nrows) && ...
                                (val.Properties.millis.VariableDims(1) == varnrows);
                        elseif strcmp(val.ClassName, 'categorical')
                            isCorrectLength = (val.Properties.codes.SizeVector(1) == nrows) && ...
                                (val.Properties.codes.VariableDims(1) == varnrows);
                        elseif strcmp(val.ClassName, 'table') || strcmp(val.ClassName, 'timetable')
                            if varnrows
                                isCorrectLength = ~isa(val.Properties.rowDim.Properties.length, 'coder.Constant');
                            else
                                isCorrectLength = isa(val.Properties.rowDim.Properties.length, 'coder.Constant') && ...
                                    (val.Properties.rowDim.Properties.length.Value == nrows);
                            end
                        else
                            isCorrectLength = (val.SizeVector(1) == nrows) && ...
                                (val.VariableDims(1) == varnrows);
                        end
                    else
                        isCorrectLength = (size(val,1) == nrows);
                    end
                else
                    % for all other assignments type.Data.xxx = yyy,
                    % do not validate
                    isCorrectLength = true;
                end
            else
                if isa(val, 'coder.Type')
                    valid = strcmp(val.ClassName, 'cell') && isequal(val.SizeVector, [1 nvars]) && ...
                        ~any(val.VariableDims);
                    if valid
                        vars = val.Cells;
                        isCorrectLength = true;
                        for i = 1:length(vars)
                            v = vars{i};
                            if strcmp(v.ClassName, 'datetime')
                                isCorrectLength = isCorrectLength && ...
                                    (v.Properties.data.SizeVector(1) == nrows) && ...
                                    (v.Properties.data.VariableDims(1) == varnrows);
                            elseif strcmp(v.ClassName, 'duration')
                                isCorrectLength = isCorrectLength && ...
                                    (v.Properties.millis.SizeVector(1) == nrows) && ...
                                    (v.Properties.millis.VariableDims(1) == varnrows);
                            elseif strcmp(v.ClassName, 'categorical')
                                isCorrectLength = isCorrectLength && ...
                                    (v.Properties.codes.SizeVector(1) == nrows) && ...
                                    (v.Properties.codes.VariableDims(1) == varnrows);
                            elseif strcmp(v.ClassName, 'table') || strcmp(v.ClassName, 'timetable')
                                if varnrows
                                    isCorrectLength = isCorrectLength && ~isa(v.Properties.rowDim.Properties.length, 'coder.Constant');
                                else
                                    isCorrectLength = isCorrectLength && isa(v.Properties.rowDim.Properties.length, 'coder.Constant') && ...
                                        (v.Properties.rowDim.Properties.length.Value == nrows);
                                end
                            else
                                isCorrectLength = isCorrectLength && ...
                                    (v.SizeVector(1) == nrows) && ...
                                    (v.VariableDims(1) == varnrows);
                            end
                        end
                    end
                else
                    valid = iscell(val) && isrow(val) && (length(val) == nvars);
                    if valid
                        isCorrectLength = true;
                        for i = 1:length(val)
                            if size(val{i},1) ~= nrows
                                isCorrectLength = false;
                                break
                            end
                        end
                    end
                end
            end
            if ~valid
                error(message('MATLAB:table:InvalidDataType', nvars));
            end
            if ~isCorrectLength
                error(message('MATLAB:table:IncorrectDataTypeHeight'));
            end
        end
        
        function x = validateVariableNames(obj, x, access)
            %% Nonconstant value and nonempty access are not supported for
            % constant properties. Do not check for errors in those cases,
            % and let them error later.
            if isa(x, 'coder.Constant') && matlab.internal.coder.type.util.isFullAssignment(access)
                val = x.Value;
                nvars = obj.Size(2);
                if ~iscellstr(val) || ~isrow(val) || (length(val) ~= nvars) || ...
                        any(cellfun('isempty', val)) %#ok<ISCLSTR>
                    error(message('MATLAB:table:InvalidVarNamesType', nvars));
                end
            end
        end
        
        function x = validateVariableDescriptions(obj, x,access)
            if isa(x, 'coder.Constant')
                val = x.Value;
            else
                val = x;
            end
            if ~matlab.internal.coder.type.util.isFullAssignment(access)
                if numel(access) == 2 && isequal({access.type}, {'.', '{}'}) && ...
                        strcmp(access(1).subs, 'Cells')
                    % assigning individual cell
                    valid = matlab.internal.coder.type.util.isCharRowType(val);
                else
                    % for all other assignments type.VariableDescriptions.xxx = yyy,
                    % do not validate
                    valid = true;
                end
            else
                % assigning to entire cell array
                nvars = obj.Size(2);
                if isa(val, 'coder.Type')
                    isrowtype = (val.SizeVector(1) == 1) && ~val.VariableDims(1);
                    isCorrectLength = (val.SizeVector(2) == nvars) && ~val.VariableDims(2);
                else
                    isrowtype = isrow(val);
                    isCorrectLength = (length(val) == nvars);
                end
                valid = isrowtype && isCorrectLength && ...
                    matlab.internal.coder.type.util.isCellstrType(val);
            end
            if ~valid
                error(message('MATLAB:table:InvalidCellstrRowType', 'VariableDescriptions', nvars));
            end
        end
        
        function x = validateVariableUnits(obj, x,access)
            if isa(x, 'coder.Constant')
                val = x.Value;
            else
                val = x;
            end
            if ~matlab.internal.coder.type.util.isFullAssignment(access)
                if numel(access) == 2 && isequal({access.type}, {'.', '{}'}) && ...
                        strcmp(access(1).subs, 'Cells')
                    % assigning individual cell
                    valid = matlab.internal.coder.type.util.isCharRowType(val);
                else
                    % for all other assignments type.VariableUnits.xxx = yyy,
                    % do not validate
                    valid = true;
                end
            else
                % assigning to entire cell array
                nvars = obj.Size(2);
                if isa(val, 'coder.Type')
                    isrowtype = (val.SizeVector(1) == 1) && ~val.VariableDims(1);
                    isCorrectLength = (val.SizeVector(2) == nvars) && ~val.VariableDims(2);
                else
                    isrowtype = isrow(val);
                    isCorrectLength = (length(val) == nvars);
                end
                valid = isrowtype && isCorrectLength && ...
                    matlab.internal.coder.type.util.isCellstrType(val);
            end
            if ~valid
                error(message('MATLAB:table:InvalidCellstrRowType', 'VariableUnits', nvars));
            end
        end
        
        function x = validateVariableContinuity(obj, x,access)
            % do not validate when access is nonempty: type.VariableContinuity.xxx = yyy
            if matlab.internal.coder.type.util.isFullAssignment(access)
                if isa(x, 'coder.Constant')
                    val = x.Value;
                    % convert from cellstr
                    if iscellstr(val) %#ok<ISCLSTR>
                        val = matlab.internal.coder.tabular.Continuity(val);
                        x = coder.Constant(val);
                    end
                else
                    if iscellstr(x) %#ok<ISCLSTR>
                        % convert from cellstr
                        x = matlab.internal.coder.tabular.Continuity(x);
                    end
                    val = x;
                end
                nvars = obj.Size(2);
                if isa(val, 'coder.Type')
                    valid = strcmp(val.ClassName, 'matlab.internal.coder.tabular.Continuity') && ...
                        isequal(val.SizeVector, [1 nvars]) && ~any(val.VariableDims);
                    
                    % Special case construction from typemaker nodes for GUI
                    valid = valid || (strcmp(val.ClassName, 'double') && ...
                        isequal([0, 0], val.SizeVector));
                else
                    valid = isa(val,'matlab.internal.coder.tabular.Continuity') && ...
                        isrow(val) && (length(val) == nvars);
                end
                if ~valid
                    error(message('MATLAB:table:InvalidContinuityType',nvars));
                end
            end
        end
    end
end