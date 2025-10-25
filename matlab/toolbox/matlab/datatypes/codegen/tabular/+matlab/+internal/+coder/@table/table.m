classdef (Sealed) table < matlab.internal.coder.tabular %#codegen
    %TABLE Table.
    
    %   Copyright 2018-2023 The MathWorks, Inc.
    
    % FIXME: should be protected
    properties(Constant, Access='public')
        propertyNames = matlab.internal.coder.table.getPropertyNamesList;
        defaultDimNames = matlab.internal.coder.tabular.private.metaDim.dfltLabels;
        RowDimNameNondefaultExceptionID = 'MATLAB:table:RowDimNameNondefault';
    end
    
    properties(Constant, Access='protected')
        % Constant properties are not persisted when serialized
        %propertyNames = matlab.internal.coder.table.getPropertyNamesList;
        %defaultDimNames = matlab.internal.coder.tabular.private.metaDim.dfltLabels;
        dispRowLabelsHeader = false;
    end
    
    properties(Access='protected')
        data
        
        % These are transient properties in non-codegen table class
        % Removed transient attribute because codegen cannot return objects
        % with transient properties
        % Create the metaDim with dim names backwards compatibility turned on
        metaDim
        rowDim
        varDim
        
        % 'Properties' will appear to contain this, as well as the per-row, per-var,
        % and per-dimension properties contained in rowDim, varDim. and metaDim,
        %arrayProps = matlab.internal.coder.tabular.arrayPropsDflts;
        arrayProps
    end
    
    methods
        function t = table(varargin)
            %TABLE Create a table from workspace variables or with a given size.
            %   T = TABLE(VAR1, VAR2, ...) creates a table T from the workspace
            %   variables VAR1, VAR2, ... .  All variables must have the same number
            %   of rows.
            %
            %   T = TABLE('Size', [N M], 'VariableTypes', {'type1', ..., 'typeM'})
            %   creates a table with the given size and variable types. Each
            %   variable in T has N rows to contain data that you assign later.
            %
            %   T = TABLE(..., 'VariableNames', {'name1', ..., 'name_M'}) creates a
            %   table containing variables that have the specified variable names.
            %   The names must be valid MATLAB identifiers, and unique.
            %
            %   T = TABLE(..., 'RowNames', {'name1', ..., 'name_N'}) creates a table
            %   that has the specified row names.  The names need not be valid MATLAB
            %   identifiers, but must be unique.
            %
            %   Tables can contain variables that are built-in types, or objects that
            %   are arrays and support standard MATLAB parenthesis indexing of the form
            %   var(i,...), where i is a numeric or logical vector that corresponds to
            %   rows of the variable.  In addition, the array must implement a SIZE method
            %   with a DIM argument, and a VERTCAT method.
            %
            %
            %   Examples:
            %      % Create a table from individual workspace variables.
            %      load patients
            %      patients = table(LastName,Gender,Age,Height,Weight,Smoker,Systolic,Diastolic)
            %      patients.Properties.Description = 'Simulated patient data';
            %      patients.Properties.VariableUnits =  {''  ''  'Yrs'  'In'  'Lbs'  ''  'mm Hg'  'mm Hg'};
            %
            %   See also READTABLE, CELL2TABLE, ARRAY2TABLE, STRUCT2TABLE.
            
            nin = nargin();
            numNamedArguments = matlab.lang.internal.countNamedArguments();
            % initialize the Dim arguments
            % metaDim is not initialized until after checking constructor inputs,
            % and stays uninitialized if requesting an uninitialized table
            t.rowDim = matlab.internal.coder.tabular.private.rowNamesDim;
            t.varDim = matlab.internal.coder.tabular.private.varNamesDim;
            
            if nin == 1 && isa(varargin{1}, 'matlab.internal.coder.datatypes.uninitialized')
                % uninitialized object requested, leave data unset
                return
            end
            
            t = t.initializeArrayProps();            
            
            if nin == 0
                % set data, rowDim, and varDim to empty
                t.rowDim = t.rowDim.createLike(0,{});
                t.varDim = t.varDim.createLike(0,{});
                t.metaDim = matlab.internal.coder.tabular.private.metaDim(2,t.defaultDimNames);
                t.data = cell(1,0);
            else
                % Count number of data variables and the number of rows, and
                % check each data variable.
                [numVars,numRows] = tabular.countVarInputs(varargin,numNamedArguments);
                
                if numVars < nargin
                    pnames = {'Size' 'VariableNames' 'VariableTypes' 'RowNames' 'DimensionNames'};
                    poptions = struct( ...
                        'CaseSensitivity',false, ...
                        'PartialMatching','first', ...
                        'StructExpand',false);
                    % parseParameterInputs allows string param names, but they
                    % are not supported in table constructor, so scan the parameter
                    % names beforehand and error if necessary. If the user had
                    % supplied any parameters using the Name=Value syntax then
                    % those names would be strings but we want to allow those,
                    % so skip the error check for those and let
                    % parseParameterInputs accept those.
                    for i = numVars+1:2:(length(varargin) - 2*numNamedArguments)
                        pname = varargin{i};
                        % Missing string is not supported in codegen, so no need to check for
                        % that.
                        coder.internal.errorIf(isstring(pname) && isscalar(pname),...
                            'MATLAB:table:StringParamNameNotSupported',pname);
                    end
                    
                    supplied = coder.internal.parseParameterInputs(pnames,poptions,varargin{numVars+1:end});
                    
                    sz = coder.internal.getParameterValue(supplied.Size,[],varargin{numVars+1:end});
                    vartypes = coder.internal.getParameterValue(supplied.VariableTypes,{},varargin{numVars+1:end});
                    dimnames = coder.internal.getParameterValue(supplied.DimensionNames,t.defaultDimNames,varargin{numVars+1:end});
                    rawvarnames = coder.internal.getParameterValue(supplied.VariableNames,{},varargin{numVars+1:end});
                    rownames = coder.internal.getParameterValue(supplied.RowNames,{},varargin{numVars+1:end});
                else
                    supplied.Size = uint32(0);
                    supplied.VariableTypes = uint32(0);
                    supplied.VariableNames = uint32(0);
                    supplied.RowNames = uint32(0);
                    dimnames = t.defaultDimNames;
                    rawvarnames = {};
                    rownames = {};
                end
                
                % Verify that dimension names and variable names are constant.
                coder.internal.assert(coder.internal.isConst(rawvarnames), ...
                                        'MATLAB:table:NonconstantVariableNames');
                coder.internal.assert(coder.internal.isConst(dimnames), ...
                                        'MATLAB:table:NonconstantDimensionNames');

                if coder.const(supplied.Size) % preallocate from specified size and var types
                    coder.internal.errorIf(numVars > 0, 'MATLAB:table:InvalidSizeSyntax');
                    coder.internal.assert(matlab.internal.datatypes.isIntegerVals(sz,0) && isequal(numel(sz),2), ...
                        'MATLAB:table:InvalidSize');
                    % in table preallocation, types must be constant
                    coder.internal.assert(coder.internal.isConst(vartypes), ...
                        'MATLAB:table:NonconstantVariableTypes');
                    sz = double(sz);
                    
                    coder.internal.assert(supplied.VariableTypes ~= 0 || sz(2) == 0, ...
                        'MATLAB:table:MissingVariableTypes');
                    coder.internal.errorIf(supplied.VariableTypes ~= 0 && ~matlab.internal.coder.datatypes.isText(vartypes,true), ...
                        'MATLAB:table:InvalidVariableTypes');
                    coder.internal.assert(isequal(sz(2), numel(vartypes)), ...
                        'MATLAB:table:VariableTypesAndSizeMismatch');
                    
                    numRows = sz(1); numVars = numel(vartypes);
                    vars = tabular.createVariables(vartypes, numRows, numVars);
                    
                    if ~supplied.VariableNames
                        % Create default var names, which never conflict with
                        % the default row times name.
                        varnames = cell(1,coder.const(numVars));
                        for i = 1:numVars
                            varnames{i} = t.varDim.dfltLabels(i,true);
                        end
                    else
                        varnames = rawvarnames;
                    end
                    
                else % create from data variables
                    varnames = rawvarnames;
                    
                    if supplied.VariableTypes
                        arg1 = varargin{1};
                        % Check for the case with no 'Size' param, but it
                        % may have been provided as "Size". Be helpful for
                        % that specific case.
                        stringsize = (numVars == 2) && (numRows == 1) && ...
                            isstring(arg1) && isscalar(arg1) && startsWith("size",arg1,'IgnoreCase',true); % partial case-insensitive
                        coder.internal.errorIf(stringsize, 'MATLAB:table:StringParamNameNotSupported',arg1);
                        % VariableTypes may not be supplied with data variables
                        coder.internal.errorIf(~stringsize, 'MATLAB:table:IncorrectVariableTypesSyntax');
                    end
                    
                    vars = cell(1,numVars);
                    for i = 1:numVars
                        vars{i} = varargin{i};
                    end
                    
                    if supplied.RowNames
                        if numVars == 0, numRows = length(rownames); end
                    end
                    
                    % codegen requires specifying variable names
                    coder.internal.assert(supplied.VariableNames ~= 0, 'MATLAB:table:MissingVariableNames');
                end
                coder.internal.prefer_const(numVars);
                % handle string (scalar) inputs
                if isstring(varnames)
                    varnames_cellstr = cellstr(varnames);
                else
                    varnames_cellstr = varnames;
                end
                if isstring(rownames)
                    rownames_cellstr = cellstr(rownames);
                else
                    rownames_cellstr = rownames;
                end
                if isstring(dimnames)
                    dimnames_cellstr = cellstr(dimnames);
                else
                    dimnames_cellstr = dimnames;
                end
                
                t = initInternals(t, vars, numRows, rownames_cellstr, numVars, ...
                    varnames_cellstr, dimnames_cellstr, t.rowDim);
                
                % Detect conflicts between the var names and the default dim names.
                t.metaDim = t.metaDim.checkAgainstVarLabels(varnames_cellstr);
            end
        end % table constructor
    end
    
    methods(Hidden, Static)
        % Called by struct2table
        function t = fromScalarStruct(s,rnames,dnames)
            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            coder.internal.assert(isstruct(s) && isscalar(s), 'MATLAB:table:NonScalarStruct');
            
            if nargin < 3
                dnames = matlab.internal.coder.table.defaultDimNames;
                if nargin < 2
                    rnames = {};
                end
            end
            
            vars = reshape(struct2cell(s), 1, []);
            [nrows,nvars] = tabular.validateVarHeights(vars);
            vnames = fieldnames(s);
            t = matlab.internal.coder.table.init(vars,nrows,rnames,nvars,vnames,dnames);
        end
        
        function t = init(vars, numRows, rowNames, numVars, varNames, dimName)
            % INIT creates a table from data and metadata.  It bypasses the input parsing
            % done by the constructor, but still checks the metadata.
            % This function is for internal use only and will change in a future release.  Do not
            % use this function.
            t = matlab.internal.coder.table(matlab.internal.coder.datatypes.uninitialized());
            
            if nargin == 6
                t = initInternals(t, vars, numRows, rowNames, numVars, varNames, dimName, t.rowDim);
            else
                t = initInternals(t, vars, numRows, rowNames, numVars, varNames, t.defaultDimNames, t.rowDim);
            end
            if numVars > 0
               t.metaDim = t.metaDim.checkAgainstVarLabels(t.varDim.labels);
            end
            t = t.initializeArrayProps();
        end
        
        function name = matlabCodegenUserReadableName
            % Make this look like a table (not the redirected table) in the codegen report
            name = 'table';
        end

        function t = matlabCodegenTypeof(~)
            t = 'matlab.coder.type.TableType';
        end
        
    end % hidden static methods block
    
    methods(Access = 'protected')
        function b = cloneAsEmpty(a) %#ok<MANU>
            %CLONEASEMPTY Create a new empty table from an existing one.
            b = table(matlab.internal.coder.datatypes.uninitialized());
        end
        
        % used by varfun and rowfun
        function id = specifyInvalidOutputFormatID(~,funName)
            id = ['MATLAB:table:' funName ':InvalidOutputFormat'];
        end

        function errID = throwSubclassSpecificErrorIf(obj,cond,msgid,varargin)
            % Throw the table version of the msgid error, using varargin as the
            % variables to fill the holes in the message.
            errID = throwSubclassSpecificErrorIf@matlab.internal.coder.tabular(obj,['table:' msgid]);
            coder.internal.errorIf(nargout == 0 && cond,errID,varargin{:});
        end
    end
    
    methods(Access = 'private', Static)        
        function propNames = getPropertyNamesList()
            % Need to manage CustomProperties which are stored in two different
            % places.
            arrayPropsMod = fieldnames(matlab.internal.coder.tabular.arrayPropsDflts);
            propNames = [arrayPropsMod; ...
                matlab.internal.coder.tabular.private.metaDim.propertyNames; ...
                matlab.internal.coder.tabular.private.varNamesDim.propertyNames; ...
                matlab.internal.coder.tabular.private.rowNamesDim.propertyNames];
        end
        
    end
    
    methods (Hidden, Static = true)
        function out = matlabCodegenFromRedirected(t)
            if isempty(t.rowDim.labels)
                rownames = cell(size(t.rowDim.labels));
            else
                rownames = t.rowDim.labels;
            end
            if isempty(t.varDim.labels)
                varnames = cell(size(t.varDim.labels));
            else
                varnames = t.varDim.labels;
            end
            if isempty(t.metaDim.labels)
                dimnames = cell(size(t.metaDim.labels));
            else
                dimnames = t.metaDim.labels;
            end
            out = table.init(t.data,t.rowDim.length,rownames,t.varDim.length,...
                varnames,dimnames);

            % Reuse matlabCodegenFromRedirected static method in
            % TableProperties to convert the properties
            tableprops = matlab.internal.coder.tabular.TableProperties.matlabCodegenFromRedirected(getProperties(t));            
            out.Properties.Description = tableprops.Description;
            out.Properties.UserData = tableprops.UserData;
            out.Properties.VariableDescriptions = tableprops.VariableDescriptions;
            out.Properties.VariableUnits = tableprops.VariableUnits;
            out.Properties.VariableContinuity = tableprops.VariableContinuity;
        end
        
        function out = matlabCodegenToRedirected(t)
            if isempty(t.Properties.RowNames)
                rownames = cell(size(t.Properties.RowNames));
            else
                rownames = t.Properties.RowNames;
            end
            if isempty(t.Properties.VariableNames)
                varnames = cell(size(t.Properties.VariableNames));
            else
                varnames = t.Properties.VariableNames;
            end
            if isempty(t.Properties.DimensionNames)
                dimnames = {};
            else
                dimnames = t.Properties.DimensionNames;
            end
            data = varfun(@(x) x, t, 'OutputFormat', 'cell');
            propsIn = getProperties(t);
            out = matlab.internal.coder.table.init(data,size(t,1),...
                rownames,size(t,2),varnames,dimnames);
            if ~isempty(propsIn.VariableDescriptions)
                out.varDim = out.varDim.setDescrs(propsIn.VariableDescriptions);
            end
            if ~isempty(propsIn.VariableUnits)
                out.varDim = out.varDim.setUnits(propsIn.VariableUnits);
            end
            if ~isempty(propsIn.VariableContinuity)
                out.varDim = out.varDim.setContinuity(cellstr(propsIn.VariableContinuity));
            end
            out = out.setDescription(propsIn.Description);
            out = out.setUserData(propsIn.UserData);
        end
        
        % should be protected
        function methodNames = getMethodNamesList()
            methodNames = {'addprop', 'addvars', 'cat', 'convertvars', ...
                'head', 'height', 'horzcat', 'inner2outer', 'innerjoin', ...
                'intersect', 'isempty', 'ismember', 'issortedrows', 'join', ...
                'mergevars', 'movevars', 'ndims', 'numel', 'outerjoin', 'renamevars' ...
                'removevars', 'rmprop', 'rowfun', 'rows2vars', 'setdiff', ...
                'setxor', 'size', 'sortrows', 'splitvars', 'stack', 'summary', ...
                'table', 'tail', 'topkrows', 'union', 'unique', 'unstack', ...
                'varfun', 'vertcat', 'width'};
        end
    end
    
    methods(Static, Access = 'protected')
        function props = getEmptyProperties()
            props = matlab.internal.coder.tabular.TableProperties;
        end
    end

    % Unsupported methods that simply return an error message
    methods(Hidden)
        function varargout = addprop(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'addprop', 'table');
        end

        function varargout = head(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'head', 'table');
        end

        function varargout = inner2outer(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'inner2outer', 'table');
        end

        function varargout = isequal(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'isequal', 'table');
        end

        function varargout = issorted(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'issorted', 'table');
        end

        function varargout = rmprop(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'rmprop', 'table');
        end

        function varargout = repelem(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'repelem', 'table');
        end

        function varargout = rowfun(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'rowfun', 'table');
        end

        function varargout = summary(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'summary', 'table');
        end

        function varargout = tail(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'tail', 'table');
        end

        function varargout = topkrows(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'topkrows', 'table');
        end

        function disp(varargin)
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'disp', 'table');
        end
    end

    % Unsupported methods: unary elementwise functions
    methods(Hidden)
        function varargout = ceil(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'ceil', 'table');
        end

        function varargout = floor(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'floor', 'table');
        end

        function varargout = fix(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'fix', 'table');
        end

        function varargout = round(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'round', 'table');
        end

        function varargout = abs(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'abs', 'table');
        end

        function varargout = cos(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cos', 'table');
        end

        function varargout = cosd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cosd', 'table');
        end

        function varargout = cosh(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cosh', 'table');
        end

        function varargout = cospi(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cospi', 'table');
        end

        function varargout = acos(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acos', 'table');
        end

        function varargout = acosd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acosd', 'table');
        end

        function varargout = acosh(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acosh', 'table');
        end

        function varargout = cot(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cot', 'table');
        end

        function varargout = cotd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cotd', 'table');
        end

        function varargout = coth(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'coth', 'table');
        end

        function varargout = acot(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acot', 'table');
        end

        function varargout = acotd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acotd', 'table');
        end

        function varargout = acoth(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acoth', 'table');
        end

        function varargout = csc(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'csc', 'table');
        end

        function varargout = cscd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cscd', 'table');
        end

        function varargout = csch(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'csch', 'table');
        end

        function varargout = acsc(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acsc', 'table');
        end

        function varargout = acscd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acscd', 'table');
        end

        function varargout = acsch(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'acsch', 'table');
        end

        function varargout = sec(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sec', 'table');
        end

        function varargout = secd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'secd', 'table');
        end

        function varargout = sech(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sech', 'table');
        end

        function varargout = asec(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'asec', 'table');
        end

        function varargout = asecd(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'asecd', 'table');
        end

        function varargout = asech(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'asech', 'table');
        end

        function varargout = sin(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sin', 'table');
        end

        function varargout = sind(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sind', 'table');
        end

        function varargout = sinh(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sinh', 'table');
        end

        function varargout = sinpi(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sinpi', 'table');
        end

        function varargout = asin(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'asin', 'table');
        end

        function varargout = asind(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'asind', 'table');
        end

        function varargout = asinh(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'asinh', 'table');
        end

        function varargout = tan(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'tan', 'table');
        end

        function varargout = tand(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'tand', 'table');
        end

        function varargout = tanh(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'tanh', 'table');
        end

        function varargout = atan(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'atan', 'table');
        end

        function varargout = atand(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'atand', 'table');
        end

        function varargout = atan2(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'atan2', 'table');
        end

        function varargout = atan2d(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'atan2d', 'table');
        end

        function varargout = atanh(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'atanh', 'table');
        end

        function varargout = exp(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'exp', 'table');
        end

        function varargout = expm1(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'expm1', 'table');
        end

        function varargout = log(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'log', 'table');
        end

        function varargout = log10(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'log10', 'table');
        end

        function varargout = log1p(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'log1p', 'table');
        end

        function varargout = log2(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'log2', 'table');
        end

        function varargout = reallog(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'reallog', 'table');
        end

        function varargout = power(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'power', 'table');
        end

        function varargout = pow2(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'pow2', 'table');
        end

        function varargout = nextpow2(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'nextpow2', 'table');
        end

        function varargout = nthroot(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'nthroot', 'table');
        end

        function varargout = sqrt(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sqrt', 'table');
        end

        function varargout = realpow(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'realpow', 'table');
        end

        function varargout = realsqrt(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'realsqrt', 'table');
        end
    end % Unsupported methods: unary elementwise functions

    % Unsupported methods: binary elementwise functions
    methods(Hidden)
        function varargout = plus(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'plus', 'table');
        end

        function varargout = minus(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'minus', 'table');
        end

        function varargout = eq(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'eq', 'table');
        end

        function varargout = ne(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'ne', 'table');
        end

        function varargout = ge(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'ge', 'table');
        end

        function varargout = gt(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'gt', 'table');
        end

        function varargout = le(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'le', 'table');
        end

        function varargout = lt(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'lt', 'table');
        end

        function varargout = and(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'and', 'table');
        end

        function varargout = or(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'or', 'table');
        end

        function varargout = not(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'not', 'table');
        end

        function varargout = xor(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'xor', 'table');
        end

        function varargout = ldivide(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'ldivide', 'table');
        end

        function varargout = rdivide(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'rdivide', 'table');
        end

        function varargout = times(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'times', 'table');
        end

        function varargout = mod(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'mod', 'table');
        end

        function varargout = rem(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'rem', 'table');
        end

    end % Unsupported methods: binary elementwise functions

    % Unsupported methods: aggregation functions
    methods(Hidden)
        function varargout = max(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'max', 'table');
        end

        function varargout = min(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'min', 'table');
        end

        function varargout = mean(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'mean', 'table');
        end

        function varargout = median(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'median', 'table');
        end

        function varargout = mode(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'mode', 'table');
        end

        function varargout = std(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'std', 'table');
        end

        function varargout = var(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'var', 'table');
        end

        function varargout = diff(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'diff', 'table');
        end

        function varargout = prod(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'prod', 'table');
        end

        function varargout = sum(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'sum', 'table');
        end

        function varargout = cummax(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cummax', 'table');
        end

        function varargout = cummin(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cummin', 'table');
        end

        function varargout = cumprod(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cumprod', 'table');
        end

        function varargout = cumsum(varargin) %#ok<STOUT>
            coder.internal.assert(false, 'Coder:toolbox:FunctionDoesNotSupportDatatype', ...
                'cumsum', 'table');
        end
    end % Unsupported methods: aggregation functions
end

