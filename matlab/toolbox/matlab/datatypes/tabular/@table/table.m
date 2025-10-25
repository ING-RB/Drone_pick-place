classdef (Sealed) table < tabular
%

%   Copyright 2012-2024 The MathWorks, Inc.

    properties(Constant, Access='protected')
        % Constant properties are not persisted when serialized

        defaultDimNames = matlab.internal.tabular.private.metaDim.dfltLabels;
        dispRowLabelsHeader = false;
    end
    
    properties(SetAccess='protected', GetAccess={?tabular,?matlab.internal.tabular.private.subscripter})
        % * DO NOT MODIFY THIS LIST OF NON-TRANSIENT INSTANCE PROPERTIES *
        % Declare any additional properties in the Transient block below,
        % and add proper logic in saveobj/loadobj to handle persistence
        
        data = cell(1,0);
    end
    
    properties(Transient, SetAccess='protected', GetAccess={?tabular,?matlab.internal.tabular.private.subscripter})
        % Create the metaDim with dim names backwards compatibility turned on
        
        metaDim = matlab.internal.tabular.private.metaDim(2,table.defaultDimNames);
        rowDim  = matlab.internal.tabular.private.rowNamesDim(0);
        varDim  = matlab.internal.tabular.private.varNamesDim(0);
        
        % 'Properties' will appear to contain this, as well as the per-row, per-var,
        % and per-dimension properties contained in rowDim, varDim. and metaDim,
        
        arrayProps = tabular.arrayPropsDflts;
    end
        
    %===========================================================================
    methods
        function t = table(varargin)
            import matlab.internal.datatypes.isText
            import matlab.internal.datatypes.isIntegerVals
            import matlab.internal.datatypes.parseArgsTabularConstructors
            import matlab.lang.internal.countNamedArguments
        
            if nargin == 0
                % Nothing to do
            else
                % Get the count of Name=Value arguments in varargin.
                try
                    numNamedArguments = countNamedArguments();
                catch
                    % If countNamedArguments fails, revert back to old behavior
                    % and assume that none of the NV pairs were passed in as
                    % Name=Value.
                    numNamedArguments = 0;    
                end
                
                % Count number of data variables and the number of rows, and
                % check each data variable.
                [numVars,numRows,nvpairs] = tabular.countVarInputs(varargin,'MATLAB:table:StringParamNameNotSupported',numNamedArguments);
                
                if numVars < nargin
                    pnames = {'Size' 'VariableTypes' 'VariableNames'  'RowNames' 'DimensionNames' };
                    dflts =  {    []              {}              {}          {}               {} };
                    partialMatchPriority = [0 0 1 0 0]; % 'Var' -> 'VariableNames' (backward compat)
                    try
                        [sz,vartypes,varnames,rownames,dimnames,supplied] ...
                            = parseArgsTabularConstructors(pnames, dflts, partialMatchPriority, ...
                                                           'MATLAB:table:StringParamNameNotSupported', ...
                                                           nvpairs{:});
                    catch ME
                        % The inputs included a 1xM char row that was interpreted as the
                        % start of param name/value pairs, but something went wrong. If
                        % all of the preceding inputs had one row, the WrongNumberArgs
                        % or BadParamName (when the unrecognized name was first among
                        % params) errors suggest that the char row might have been
                        % intended as data. Suggest alternative options in that case.
                        % Only suggest this alternative if the char row vector
                        % did not come from Name=Value.
                        errIDs = {'MATLAB:table:parseArgs:WrongNumberArgs' ...
                                  'MATLAB:table:parseArgs:BadParamNamePossibleCharRowData'};
                        namedArgumentsStart = nargin - 2*numNamedArguments + 1;
                        if matches(ME.identifier,errIDs)
                            if ((numVars == 0) || (numRows == 1)) && (namedArgumentsStart > numVars+1)
                                pname1 = varargin{numVars+1}; % always the first char row vector
                                ME = ME.addCause(MException(message('MATLAB:table:ConstructingFromCharRowData',pname1)));
                            end
                        end
                        % 'StringParamNameNotSupported' suggests the opposite: a 1-row string intended as a param.
                        throw(ME);
                    end
                else
                    supplied.Size = false;
                    supplied.VariableTypes = false;
                    supplied.VariableNames = false;
                    supplied.RowNames = false;
                    supplied.DimensionNames = false;
                end
                
                if supplied.Size % preallocate from specified size and var types
                    if numVars > 0
                        % If using 'Size' parameter, cannot have data variables as inputs
                        error(message('MATLAB:table:InvalidSizeSyntax'));                    
                    elseif ~isIntegerVals(sz,0) || ~isequal(numel(sz),2)
                        error(message('MATLAB:table:InvalidSize'));
                    end
                    sz = double(sz);
                    
                    if sz(2) == 0
                        % If numVars is 0, VariableTypes must be empty (or not supplied)
                        if ~isequal(numel(vartypes),0)
                            error(message('MATLAB:table:VariableTypesAndSizeMismatch'))
                        end
                    elseif ~supplied.VariableTypes
                        error(message('MATLAB:table:MissingVariableTypes'));
                    elseif ~isText(vartypes,true) % require list of names
                        error(message('MATLAB:table:InvalidVariableTypes'));
                    elseif ~isequal(sz(2), numel(vartypes))
                        error(message('MATLAB:table:VariableTypesAndSizeMismatch'))
                    end
                    
                    numRows = sz(1); numVars = sz(2);
                    vars = tabular.createVariables(vartypes,sz);
                    
                    if ~supplied.VariableNames
                        % Create default var names, which never conflict with
                        % the default row times name.
                        varnames = t.varDim.dfltLabels(1:numVars);
                    end
                    
                else % create from data variables
                    if supplied.VariableTypes
                        if (numVars == 2) && (numRows == 1)
                            % Apparently no 'Size' param, but it may have been provided as
                            % "Size". Be helpful for that specific case.
                            arg1 = varargin{1};
                            if isstring(arg1) && isscalar(arg1) && startsWith("size",arg1,'IgnoreCase',true) % partial case-insensitive
                                error(message('MATLAB:table:StringParamNameNotSupported',arg1));
                            end
                        end

                        if numVars > 0
                            % VariableTypes may not be supplied with data variables
                            error(message('MATLAB:table:IncorrectVariableTypesSyntax'));
                        elseif ~supplied.Size
                            % check that Size was supplied alongside VariableTypes
                            error(message('MATLAB:table:MissingSize'));
                        end
                    end
                    
                    vars = varargin(1:numVars);
                    
                    if supplied.RowNames
                        if numVars == 0, numRows = length(rownames); end
                    else
                        rownames = {};
                    end

                    if ~supplied.VariableNames
                        % Get the workspace names of the input arguments from inputname
                        varnames = repmat({''},1,numVars);
                        for i = 1:numVars, varnames{i} = inputname(i); end
                        % Fill in default names for data args where inputname couldn't
                        empties = cellfun('isempty',varnames);
                        if any(empties)
                            varnames(empties) = t.varDim.dfltLabels(find(empties));
                        end
                        % Make sure default names or names from inputname don't conflict
                        varnames = matlab.lang.makeUniqueStrings(varnames,{},namelengthmax);
                    end
                end
                
                if supplied.DimensionNames
                    t = t.initInternals(vars, numRows, rownames, numVars, varnames, dimnames);
                else
                    t = t.initInternals(vars, numRows, rownames, numVars, varnames);
                end
                
                % Detect conflicts between the var names and the default dim names.
                t.metaDim = t.metaDim.checkAgainstVarLabels(varnames);
            end
        end % table constructor
    end % methods block
    
    %===========================================================================
    methods(Hidden) % hidden methods block
        write(t,filename,varargin)
        
        %% Error stubs
        % Methods to override functions and throw helpful errors
         function t = cell(t,varargin)
            import matlab.lang.correction.ReplaceIdentifierCorrection
            throw(MException(message('MATLAB:table:UndefinedCellFunction',class(t))) ...
            	.addCorrection(ReplaceIdentifierCorrection('cell','table2cell')));
         end
    end
            
    %===========================================================================
    methods(Hidden, Static)
        
        function t = empty(varargin)
            %

            % Store an empty table as a persistent variable for performance.
            persistent tEmpty

            if isnumeric(tEmpty) % uninitialized
                tEmpty = table();
            end
            
            if nargin == 0
                t = tEmpty;
            else
                sizeOut = size(zeros(varargin{:}));
                if prod(sizeOut) ~= 0
                    error(message('MATLAB:class:emptyMustBeZero'));
                elseif length(sizeOut) > 2
                    error(message('MATLAB:table:empty:EmptyMustBeTwoDims'));
                else
                    % Create a 0x0 table, and then resize to the correct number
                    % of rows or variables.
                    t = tEmpty;
                    if sizeOut(1) > 0
                        t.rowDim = t.rowDim.lengthenTo(sizeOut(1));
                    end
                    if sizeOut(2) > 0
                        t.varDim = t.varDim.lengthenTo(sizeOut(2));
                        t.data = cell(1,sizeOut(2)); % assume double
                    end
                end
            end
        end
        
        function t = fromScalarStruct(s,rnames,dnames)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            if ~(isstruct(s) && isscalar(s))
                error(message('MATLAB:table:NonScalarStruct'))
            end
            vars = struct2cell(s)';

            for i = 1:numel(vars)
                % Wrap a function_handle variable in a cell so the variable can grow.
                %
                % Vectors of function_handle are not legal. If the function_handle variable in
                % t is not wrapped in a cell, then rows can never be added to t because
                % concatenation of the function_handle with another array will throw an error
                % in most cases.
                if isa(vars{i}, 'function_handle') % Consider a concatenation-based check like in container2vars?l
                    if isempty(vars{i})
                        % Return a cell, but one that preserves the height of the empty function handle
                        % for the validateVarHeights check below.
                        vars{i} = cell.empty(size(vars{i}));
                    else
                        vars{i} = { vars{i} }; % wrap the function_handle in a cell
                    end
                end
            end

            [nrows,nvars] = tabular.validateVarHeights(vars);
            vnames = fieldnames(s);
            
            if nargin < 3
                if nargin < 2, rnames = {}; end
                t = table.init(vars,nrows,rnames,nvars,vnames);
            else
                t = table.init(vars,nrows,rnames,nvars,vnames,dnames);
            end
        end
        
        function t = init(vars, numRows, rowNames, numVars, varNames, dimNames)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            try %#ok<ALIGN>
            
            % INIT creates a table from data and metadata.  It bypasses the input parsing
            % done by the constructor, but still checks the metadata.
            t = table();
            if nargin == 6
                t = t.initInternals(vars, numRows, rowNames, numVars, varNames, dimNames);
            else
                t = t.initInternals(vars, numRows, rowNames, numVars, varNames);
            end
            if numVars > 0
                t.metaDim = t.metaDim.checkAgainstVarLabels(t.varDim.labels);
            end
            
            catch ME, throwAsCaller(ME); end
        end
        
        function t = createArray(varargin)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            t = tabular.createArrayImpl(@(fillval)table(fillval),varargin{:});
        end
        
        function t = setReadtableMetaData(t,rawData, readRowNames,readVarNames,varNames,rowNames,dimNames,fixIllegal)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            % Set the var names.  These will be modified to make them valid, and the
            % original strings saved in the VariableDescriptions property. Fix up duplicate
            % or empty names.
            if fixIllegal
                fixIllegal = "fixIllegal";
            else
                fixIllegal = "fixTooLong";
            end
            t.varDim = t.varDim.setLabels(varNames,[],true,true,fixIllegal);
            

            if ~isempty(rawData) && readRowNames
                t.rowDim = t.rowDim.setLabels(rowNames,[],true,true,true); % Fix up duplicate or empty names, or reserved name (':')
                t.metaDim = t.metaDim.setLabels(dimNames,[],true,true,true); % Fix up duplicate, empty, invalid, or reserved names
            end
            if readVarNames
                % Make sure var names and dim names don't conflict. That could happen if var
                % names read from the file are the same as the default dim names (when ReadRowNames
                % is false), or same as the first dim name read from the file (ReadRowNames true).
                t.metaDim = t.metaDim.checkAgainstVarLabels(t.varDim.labels,'silent');
            end
        end
    end % hidden static methods block
        
    %===========================================================================
    methods(Access = 'protected')
        function propNames = propertyNames(t)
            %

            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            persistent names

            if isnumeric(names)
            % Need to manage CustomProperties which are stored in two different
            % places.
                arrayPropsMod = tabular.arrayPropsDflts;
                arrayPropsMod = rmfield(arrayPropsMod, 'TableCustomProperties');
                arrayPropsMod = fieldnames(arrayPropsMod);
                names = [arrayPropsMod; ...
                         t.metaDim.propertyNames; ...
                         t.varDim.propertyNames; ...
                         t.rowDim.propertyNames; ...
                         'CustomProperties'];
            end
            propNames = names;
        end
        
        function p = emptyPropertiesObj(t) %#ok<MANU>
            persistent props

            if isnumeric(props)
                props = matlab.tabular.TableProperties;
            end
            
            p = props;
        end

        function b = cloneAsEmpty(~)
            %

            %CLONEASEMPTY Create a new empty table from an existing one.
%             if strcmp(class(a),'table') %#ok<STISA>
                % call table.empty instead of table() for better performance.
                b = table.empty;
%             else % b is a subclass of table
%                 b = a; % respect the subclass
%                 % leave b.metaDim alone
%                 b.rowDim = b.rowDim.shortenTo(0);
%                 b.varDim = b.varDim.shortenTo(0);
%                 b.data = cell(1,0);
%                 leave b.arrayProps alone
%             end
        end
        
        function errID = throwSubclassSpecificError(obj,msgid,varargin)
            %

            % THROWSUBCLASSSPECIFICERROR Throw the table version of the msgid
            % error, using varargin as the variables to fill the holes in the
            % message. 
            errID = throwSubclassSpecificError@tabular(obj,['table:' msgid],varargin{:});
            if nargout == 0
                throwAsCaller(errID);
            end
        end
        
        function rowLabelsStruct = summarizeRowLabels(~,~,~,~)
            %

            % SUMMARIZEROWLABELS is called by summary method to get a struct containing
            % a summary of the row labels.
            
            % Empty for table
            rowLabelsStruct = struct;
        end

        function printRowLabelsSummary(~,~,~)
            %

            % PRINTROWLABELSSUMMARY is called by summary method to print the row labels
            % summary. No-op for table.
        end
        
        % used by varfun and rowfun
        function id = specifyInvalidOutputFormatID(~,funName)
            id = "MATLAB:table:" + funName + ":InvalidOutputFormat";
        end
    end


    %===========================================================================
    methods(Access = 'protected')
        function [t, t_idx] = getTemplateForConcatenation(~,varargin)
            %

            % GETTEMPLATEFORCONCATENATION Get the output template for table
            % concatenation that has the correct class and the correct type for
            % the dim objects.

            % Since table is inferior to other tabular classes, if we are
            % dispatched to table.getTemplateForConcatenation, then the inputs
            % must only contain tables and cell arrays. Hence the output type
            % will always be table. Go through the list of inputs and select
            % the first non-0x0 table as the template.

            t = [];
            t_idx = 0;
            t_is0x0 = true;
            t_hasRowLabels = false;
            t_uninitialized = true;
            i = 1;
            while i < nargin
                b = varargin{i};
                b_is0x0 = sum(size(b)) == 0;
                if isa(b,'table')
                    if t_uninitialized ...
                        || (t_is0x0 && ~b_is0x0)
                        % Use b as the template if either the template was
                        % uninitialized or if it was initialized from a 0x0
                        % table and b is a non-0x0 table.
                        t = b;
                        t_idx = i;
                        t_is0x0 = b_is0x0;
                        t_hasRowLabels = b.rowDim.hasLabels;
                        t_uninitialized = false;
                    end
                    if ~t_hasRowLabels && (~b_is0x0 && b.rowDim.hasLabels)
                        % If the template does not have row names but we
                        % encounter a non-0x0 table with row names, then update
                        % the template to use b's rowDim.
                        t.rowDim = b.rowDim;
                        t_hasRowLabels = true;
                    end
                elseif isa(b,'cell')
                    if ~b_is0x0 && (t_uninitialized || t_is0x0)
                        % If b is a non-0x0 cell and the template was either
                        % uninitialized or initialized from a 0x0 table, then
                        % convert b into a table and use that as the template.
                        % This ensure we create a table with correct size and
                        % default properties, when cat'ing 0x0 table with cell
                        % arrays.
                        vnames = matlab.internal.tabular.private.varNamesDim.dfltLabels(1:size(b,2));
                        t = cell2table(b,VariableNames=vnames);
                        t_idx = i;
                        % Set t_is0x0 to true to force a reinitialization if we
                        % encounter a non-0x0 table further down the road.
                        t_is0x0 = true;
                        t_uninitialized = false;
                    end
                end
                i = i + 1;
            end
        end
    end
    
    %===========================================================================
    methods(Access = 'private', Static)        
        function propNames = getPropertyNamesList()
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            % Need to manage CustomProperties which are stored in two different
            % places.
            arrayPropsMod = tabular.arrayPropsDflts;
            arrayPropsMod = rmfield(arrayPropsMod, 'TableCustomProperties');
            arrayPropsMod = fieldnames(arrayPropsMod);
            propNames = [arrayPropsMod; ...
                matlab.internal.tabular.private.metaDim.propertyNames; ...
                matlab.internal.tabular.private.varNamesDim.propertyNames; ...
                matlab.internal.tabular.private.rowNamesDim.propertyNames; ...
                'CustomProperties'];
        end
    end
    
    %%%%% PERSISTENCE BLOCK ensures correct save/load across releases %%%%%
    %%%%% Properties and methods in this block maintain the exact class %%%
    %%%%% schema required for TABLE to persist through MATLAB releases %%%%
    properties(Constant, Access='protected')
        % Version of this table serialization and deserialization format.
        % This is used for managing forward compatibility. Value is saved
        % in 'versionSavedFrom' when an instance is serialized.
        %
        %   1.0 : 13b. first shipping version
        %   2.0 : 16b. re-architecture for tabular
        %   2.1 : 17b. added continuity
        %   2.2 : 18a. added serialized field 'incompatibilityMsg' to support 
        %              customizable 'kill-switch' warning message. The field
        %              is only consumed in loadobj() and does not translate
        %              into any table property.
        %   3.0 : 18b. added 'CustomProps' and 'VariableCustomProps' via
        %              tabular/saveobj to preserve per-table and per-variable
        %              custom properties
        %   4.0 : 19b. allow variable names in tables to include arbitrary
        %              characters. They no longer must be valid MATLAB identifiers.
        %   5.0 : 25a. namelengthmax increased from 63 to 2048.

        version = 5.0;
    end

    properties(Access='private')
        % ** DO NOT EDIT THIS LIST OR USE THESE PROPERTIES INSIDE TABLE **
        % These properties mirror the pre-R2016b internal representation, which was also
        % the external representation saved to mat files. Post-R2016b saveobj and loadobj
        % continue to use them as the external representation for save/load compatibility
        % with earlier releases.
        
        ndims;
        nrows;
        rownames;
        nvars;
        varnames;
        props;
    end
    
    methods(Hidden)
        tsave = saveobj(t)
    end
    
    methods(Hidden, Static)
        t = loadobj(s)

        function name = matlabCodegenRedirect(~)
            % This function is for internal use only and will change in a future release.
            % Do not use this function.
            
            % Use the implementation in the class below when generating
            % code.
            name = 'matlab.internal.coder.table';
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%% END PERSISTENCE BLOCK %%%%%%%%%%%%%%%%%%%%%%%%
end % classdef
