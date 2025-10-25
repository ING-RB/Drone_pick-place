classdef (AllowedSubclasses = {...
                                ?matlab.io.text.TextImportOptions,...
                                ?matlab.io.spreadsheet.SpreadsheetImportOptions,...
                                ?matlab.io.xml.XMLImportOptions,...
                                ?matlab.io.html.HTMLImportOptions,...
                                ?matlab.io.word.WordDocumentImportOptions}) ...
                                ImportOptions < matlab.io.internal.mixin.HasPropertiesAsNVPairs...
                                & matlab.mixin.internal.Scalar ...
                                & matlab.io.internal.shared.MissingErrorRulesInputs ...
                                & matlab.io.internal.shared.PreserveVariableNamesInput ...
                                & matlab.io.internal.shared.save.Saveable
    properties (Dependent)
        %SELECTEDVARIABLENAMES Names of variables of interest
        %   By default, SelectedVariableNames is equal to VariableNames. It can be
        %   set to any unique subset of the VariableNames to indicate which
        %   variables should be imported.
        %
        %   See also matlab.io.spreadsheet.SpreadsheetImportOptions
        SelectedVariableNames

        %VARIABLENAMES Names of variables
        %   The names to use when importing variables. If empty, variable names
        %   will be read from data, or generated as Var1, Var2, etc..
        %
        %   See also matlab.io.spreadsheet.SpreadsheetImportOptions
        VariableNames

        %VARIABLEOPTIONS Options for each import variable
        %   VariableOptions is an array of VariableImportOptions of the same size
        %   as variable names. Each element of the array sets options for a
        %   specific variable.
        %
        %   Example, setting an option for a variable by name:
        %       opts = detectImportOptions('patients.xls')
        %       opts = setvaropts(opts,'Gender','MissingRule','error');
        %
        %   See also matlab.io.spreadsheet.SpreadsheetImportOptions
        %   matlab.io.spreadsheet.SpreadsheetImportOptions/setvaropts
        %   matlab.io.spreadsheet.SpreadsheetImportOptions/getvaropts
        %   matlab.io.VariableImportOptions
        VariableOptions

        %VARIABLETYPES Output types of the variables
        %   VariableTypes is a cell array of character vectors whose values
        %   indicate the datatype of the variable.
        %   The following types (and resulting import variables) are supported:
        %   * char - a cell array of character vectors
        %   * double - a double precision floating point number array
        %   * single - a single precision floating point number array
        %   * datetime - a datetime array
        %   * duration - a duration array
        %   * categorical - a categorical array
        %   * int8 - an 8-bit integer array
        %   * int16 - a 16-bit integer array
        %   * int32 - a 32-bit integer array
        %   * int64 - a 64-bit integer array
        %   * uint8 - an unsigned 8-bit integer array
        %   * uint16 - an unsigned 16-bit integer array
        %   * uint32 - an unsigned 32-bit integer array
        %   * uint64 - an unsigned 64-bit integer array
        %   * logical - a logical array
        %
        %   See also matlab.io.spreadsheet.SpreadsheetImportOptions
        %   matlab.io.VariableImportOptions
        %   matlab.io.TextVariableImportOptions
        %   matlab.io.NumericVariableImportOptions
        %   matlab.io.DatetimeVariableImportOptions
        %   matlab.io.DurationVariableImportOptions
        %   matlab.io.CategoricalVariableImportOptions
        VariableTypes
    end

    properties (Access = private)
        selected_vars = ':';
        is_unbounded_selection(1,1) = true;
        using_generated_names(1,1) = true;
        var_opts = [];
    end

    properties (Dependent, Access = ...
                {?matlab.io.internal.functions.DetectImportOptionsText,...
                 ?matlab.io.internal.functions.DetectImportOptionsSpreadsheet,...
                 ?matlab.io.internal.functions.ReadMatrixWithImportOptions,...
                 ?matlab.io.internal.functions.ReadTimeTableWithImportOptions,...
                 ?matlab.io.internal.functions.ReadTableWithImportOptionsText,...
                 ?matlab.io.internal.functions.ReadTableWithImportOptionsSpreadsheet,...
                 ?matlab.io.internal.functions.ReadTableWithImportOptionsXML,...
                 ?matlab.io.internal.functions.SetVarOpts,...
                 ?matlab.io.ImportOptions,...
                 ?matlab.io.text.internal.TabularTextReader,...
                 ?matlab.io.internal.builders.Builder})
        selectedIDs;
    end

    properties (Access = ...
                {?matlab.io.internal.functions.DetectImportOptionsText,...
                 ?matlab.io.internal.functions.DetectImportOptionsSpreadsheet,...
                 ?matlab.io.internal.functions.DetectImportOptionsXML,...
                 ?matlab.io.internal.shared.HexBinaryType,...
                 ?matlab.io.internal.functions.ReadMatrixWithImportOptions,...
                 ?matlab.io.internal.functions.ReadTimeTableWithImportOptions,...
                 ?matlab.io.internal.functions.ReadTableWithImportOptionsText,...
                 ?matlab.io.internal.functions.ReadTableWithImportOptionsSpreadsheet,...
                 ?matlab.io.internal.functions.SetVarOpts,...
                 ?matlab.io.ImportOptions,...
                 ?matlab.io.text.internal.TabularTextReader,...
                 ?matlab.io.internal.builders.Builder})
        fast_var_opts matlab.io.internal.FastVarOpts = matlab.io.internal.FastVarOpts(1);
    end

    properties (Hidden)
        %EmptyColumnType  Datatype of empty columns
        %   What type to use when returning empty columns. For backward
        %   comptability purposes, currently we are passing in char for
        %   detectImportOptions, and double for
        %   readtable/datastore/spreadsheet.
        EmptyColumnType char
    end

    properties(Hidden, Dependent)
        %DefaultDatetimeLocale  Default date locale to use when importing text
        %   as dates. To control the locale on a per variable basis,
        %   specify the DefaultDatetimeLocale via setvaropts.
        DefaultDatetimeLocale
    end

    properties (Constant, Access = protected)
        % PreviewSize   Maximum number of rows the preview method returns.
        PreviewSize = 8;
    end

    methods
        function val = get.selectedIDs(obj)
            if strcmp(obj.selected_vars,':')
                val = 1:obj.fast_var_opts.numVars();
            else
                val = obj.selected_vars;
            end
        end

        function obj = set.VariableTypes(obj,types)
            vopts = obj.fast_var_opts;
            n = vopts.numVars;
            if ischar(types), types = {types}; end
            if numel(types) ~= n
                error(message('MATLAB:textio:io:ExpectedCellStrSize',n))
            end
            obj.fast_var_opts = vopts.setTypes(1:n,types(:));
        end

        function obj = set.VariableOptions(obj,rhs)
            if ~isa(rhs,'matlab.io.VariableImportOptions') || (~isvector(rhs) && ~isempty(rhs))
                error(message('MATLAB:textio:io:ExpectedVarImportOpts'))
            end
            % replace empty names with Var##
            nNew = numel(rhs);
            oldNames = obj.fast_var_opts.Names;
            nOld = obj.fast_var_opts.numVars;

            obj.fast_var_opts = matlab.io.internal.FastVarOpts.fromFullVarOpts(rhs);

            if nOld ~= nNew
                obj = updatePerVarSizes(obj,nNew);
                obj.using_generated_names = false;
            else
                obj.using_generated_names = all(string(oldNames)==string(obj.fast_var_opts.Names));
            end
            if obj.is_unbounded_selection && ~isequal(obj.selected_vars,':')
                obj.selected_vars = [obj.selected_vars nOld+1:nNew];
            end
        end

        function obj = set.SelectedVariableNames(obj,rhs)
            if (iscell(rhs) && ~iscellstr(rhs)) %#ok<ISCLSTR>
                error(message('MATLAB:textio:io:BadSelectionInput'));
            else
                rhs = matlab.io.internal.validators.validateCellStringInput(rhs,'Selected Variable Names');
            end
            if isnumeric(rhs)
                n = obj.fast_var_opts.numVars;
                if ~all(rhs >= 1 & rhs <= n) || ~all(floor(rhs)==rhs)
                    error(message('MATLAB:textio:io:BadNumericSelection'));
                end
            elseif ischar(rhs) || iscell(rhs)
                rhs = convert2cellstr(rhs);
                rhs = getNumericSelection(obj,rhs);
            else
                error(message('MATLAB:textio:io:BadSelectionInput'))
            end
            obj.selected_vars = unique(rhs,'stable');
            obj.is_unbounded_selection = isequal(rhs,':');
        end

        function val = get.VariableNames(obj)
        % TODO change this so, we don't have to do the transpose
            val = obj.fast_var_opts.Names';
            if isa(obj,'matlab.io.internal.mixin.UsesStringsForPropertyValues')
                val = string(val);
            end
        end

        function val = get.VariableTypes(obj)
        % TODO change this so, we don't have to do the transpose
            val = obj.fast_var_opts.Types';
            if isa(obj,'matlab.io.internal.mixin.UsesStringsForPropertyValues')
                val = string(val);
            end
        end

        function val = get.VariableOptions(obj)
            val = obj.fast_var_opts.getVarOpts();
        end

        function val = get.SelectedVariableNames(obj)
            val = obj.fast_var_opts.Names(obj.selected_vars,:)';
            if isa(obj,'matlab.io.internal.mixin.UsesStringsForPropertyValues')
                val = string(val);
            end
        end

        function obj = set.VariableNames(obj,newNames)
            newNames = convertStringsToChars(newNames);
            if ischar(newNames)
                newNames = {newNames};
            end
            newNames = newNames(:);

            import matlab.io.internal.validators.validateVariableName;
            validateFcn = @(name) validateVariableName(name, false);

            if ~iscell(newNames) || ~all(cellfun(validateFcn,newNames))
                error(message('MATLAB:textio:io:BadVariableNames', namelengthmax));
            end

            iscellofstrings = ~(iscellstr(newNames) || ischar(newNames) || isstring(newNames));
            if iscellofstrings
                error(message('MATLAB:makeUniqueStrings:InvalidInputStrings'));
            end
            nOld = obj.fast_var_opts.numVars;
            nNew = numel(newNames);
            if nOld ~= nNew
                if nOld < nNew % Adding new names
                               % Make the new names unique, preserving the old names
                    obj.fast_var_opts = obj.fast_var_opts.addVars(nNew - nOld);
                else
                    obj.fast_var_opts = obj.fast_var_opts.removeVars(nNew+1:nOld);
                end

                obj = updatePerVarSizes(obj,nNew);
                if obj.is_unbounded_selection && ~isequal(obj.selected_vars,':')
                    obj.selected_vars = [obj.selected_vars nOld+1:nNew];
                end
                % any selected names out of range should be removed
                if ~ischar(obj.selected_vars)
                    obj.selected_vars(obj.selected_vars > nNew)=[];
                end
            end

            % If incoming names conflict with any pre-set existing names,
            % make those new names unique. This should ensure that any
            % names assigned by the user remain unique.
            oldNames = obj.fast_var_opts.OptionsStruct.Names;
            changedNames = ~strcmp(oldNames,newNames);
            newNames(changedNames) = matlab.lang.makeUniqueStrings(newNames(changedNames),...
                                                                   oldNames(~changedNames), namelengthmax); % Keep the old names that were not changed

            obj.fast_var_opts.Names = newNames;
            obj.using_generated_names = false;
        end

        function obj = set.NumVariables(obj,rhs)
        % Expect a non-negative scalar integer
            rhs = matlab.io.internal.common.validateNonNegativeScalarInt(rhs);
            obj.fast_var_opts = matlab.io.internal.FastVarOpts(rhs);
            obj = updatePerVarSizes(obj,rhs);
        end

        function numVars = get.NumVariables(obj)
            numVars = obj.NumVariables;
        end

        function dateLocale = get.DefaultDatetimeLocale(obj)
            dateLocale = obj.fast_var_opts.DefaultDatetimeLocale;
            if isa(obj,'matlab.io.internal.mixin.UsesStringsForPropertyValues')
                dateLocale = convertCharsToStrings(dateLocale);
            end
        end

        function obj = set.DefaultDatetimeLocale(obj, rhs)
            obj.fast_var_opts.DefaultDatetimeLocale = rhs;
        end
    end

    methods (Abstract, Access = protected)
        obj = updatePerVarSizes(obj,nNew);
        addCustomPropertyGroups(opts,helper);
        modifyCustomGroups(opts,helper);
        verifyMaxVarSize(obj,n);
    end

    methods % class functions
        opts = setvartype(opts,varargin)
        opts = setvaropts(opts,varargin)
        vopts = getvaropts(opts,selection)
    end

    methods (Hidden)
        function tf = isequal(opts1,opts2)
        % Import Options should be equal regardless of the missing
        % comparisons in the FillValue properties.
            tf = isequaln(opts1,opts2);
        end

        function tf = isequaln(opts1,opts2)
            tf = false;

            % Same classes?
            if ~strcmp(class(opts1),class(opts2)); return; end

            % Same number of variables?
            n1 = opts1.fast_var_opts.numVars();
            n2 = opts2.fast_var_opts.numVars();
            if n1 ~= n2; return; end

            % Same Variable Options?
            vo1 = opts1.fast_var_opts.getVarOptsStruct(1:n1);
            vo2 = opts2.fast_var_opts.getVarOptsStruct(1:n2);
            if ~isequaln(vo1,vo2); return; end

            % remove the variable options to compare the remaining
            % properties
            opts1.fast_var_opts = opts1.fast_var_opts.removeVars(1:n1);
            opts2.fast_var_opts = opts2.fast_var_opts.removeVars(1:n2);
            % This field shouldn't be compared.
            opts1.using_generated_names = opts2.using_generated_names;
            tf = builtin('isequaln',opts1,opts2);
        end
    end

    methods (Access = private)
        function idx = getNumericSelection(obj,selection)
            selection = convert2cellstr(selection);
            if isscalar(selection) && strcmp(selection,':')
                % Select Everything
                idx = 1:obj.fast_var_opts.numVars;
            else
                [~,idx] = ismember(selection, obj.fast_var_opts.Names');
                if any(idx==0)
                    error(message('MATLAB:textio:io:UnknownVarName',selection{find(idx==0,1)}));
                end
            end
        end

        function selection = fixSelection(opts,selection)
            if iscell(selection) || ischar(selection)
                selection = opts.getNumericSelection(selection);
            elseif isnumeric(selection)
                if ~all(selection > 0 & isfinite(selection) & floor(selection)==selection & selection <= numel(opts.fast_var_opts))
                    error(message('MATLAB:textio:io:BadNumericSelection'));
                end
            else
                error(message('MATLAB:textio:io:BadSelectionInput'));
            end
        end
    end

    methods (Static, Hidden)
        function [opts,rrn,rvn,args] = validateReadtableInputs(opts, args)
            persistent parser
            if isempty(parser)
                parser = inputParser();
                parser.FunctionName = 'readtable';
                parser.KeepUnmatched = true;
                parser.addParameter('ReadVariableNames',false,@(tf)validateLogical(tf,'ReadVariableNames'));
                parser.addParameter('ReadRowNames',false,@(tf)validateLogical(tf,'ReadRowNames'));
            end
            [args{:}] = convertStringsToChars(args{:});
            parser.parse(args{:});
            params = parser.Results;

            rrn = params.ReadRowNames;
            if rrn && ~opts.usingRowNames()
                % User didn't define a rownamesColumn, but called readtable with ReadRowNames
                opts = opts.setRowNames(true);
            elseif ~rrn && ~any(strcmp('ReadRowNames',parser.UsingDefaults)) && opts.usingRowNames()
                % User specified a RowNamesColumn, but asked readtable not to import it.
                % set the RowNames back to default
                opts = opts.setRowNames(false);
            end

            rvn = params.ReadVariableNames;

        end
    end

    methods (Static, Access = protected)
        function obj = setAllProps(obj,s)
            if isfield(s,'var_opts') && isa(s.var_opts,'matlab.io.VariableImportOptions')
                s.fast_var_opts = matlab.io.internal.FastVarOpts.fromFullVarOpts(s.var_opts);
                s = rmfield(s, "var_opts");
            end
            obj.fast_var_opts = s.fast_var_opts;
            s = rmfield(s, "fast_var_opts");
            for f = fieldnames(s)'
                obj.(f{1}) = s.(f{1}); % f is a 1x1 cell array containing the name of a field in struct s
            end
        end

        function obj = loadImportOptions(s, type)
        % Helper method used when loading Import Options objects from a
        % MAT file. This method sets the properties common to all
        % Import Options object.
            if isstruct(s)
                obj = matlab.io.ImportOptions.getImportOptionsByType(type);

                % older import options saved VariableImportOptions
                % instead of FastVarOpts
                if ~isfield(s, "fast_var_opts")
                    s.fast_var_opts = matlab.io.internal.FastVarOpts.fromFullVarOpts(s.var_opts);
                end

                if ~isfield(s, "is_unbounded_selection")
                    s.is_unbounded_selection = isequal(s.selected_vars,':');
                end

                typeSpecificProps = obj.getTypeSpecificProperties();
                commonProps = ["fast_var_opts", "ImportErrorRule", "MissingRule",...
                               "EmptyColumnType", "PreserveVariableNames",...
                               "selected_vars", "is_unbounded_selection"];
                props = [commonProps typeSpecificProps];

                for ii = 1:numel(props)
                    try
                        % Some properties may not be fields in the struct
                        % if options were saved in earlier releases.
                        obj.(props(ii)) = s.(props(ii));
                    catch ME
                        % Expect a non Existent Field error if loading a
                        % new property that did not exist in an older
                        % release. In this case, the new property is set to
                        % the default value. Otherwise, we have an invalid
                        % value and we will issue the error as a
                        % warning.
                        if ~strcmp(ME.identifier, 'MATLAB:nonExistentField')
                            warning(ME.identifier, '%s', ME.message);
                        end
                    end
                end

                if isfield(s, "using_generated_names")
                    obj.using_generated_names = s.using_generated_names;
                else
                    % set using_generated_names to false if the struct does
                    % not have this field.
                    obj.using_generated_names = false;
                end

            else % loading from an object
                obj = s;

                % if numVars is 1, there is no way to kow if fast_var_opts
                % was loaded from the MAT file or if it was constructed
                % during the creation of a default ImportOptions object.
                if obj.fast_var_opts.numVars() == 1
                    % preserve the old DateLocale from the loaded options
                    oldLocale = obj.fast_var_opts.DefaultDatetimeLocale;
                    obj.fast_var_opts = matlab.io.internal.FastVarOpts.fromFullVarOpts(obj.var_opts);
                    obj.fast_var_opts.DefaultDatetimeLocale = oldLocale;
                end
                obj.var_opts = [];
            end
        end
    end

    methods(Static, Access = private)
        function obj = getImportOptionsByType(type)
            switch type
              case "fixed"
                obj = matlab.io.text.FixedWidthImportOptions;
              case "delimited"
                obj = matlab.io.text.DelimitedTextImportOptions;
              case "spreadsheet"
                obj = matlab.io.spreadsheet.SpreadsheetImportOptions;
              otherwise
                assert(false);
            end
        end
    end

    methods(Static, Abstract, Access = protected)
        props = getTypeSpecificProperties();
    end

    methods (Hidden)

        function T  = readtable(filename,opts,varargin)
            if ~isa(opts,'matlab.io.ImportOptions')
                error(message('MATLAB:textio:io:OptsSecondArg','readtable'))
            end
            try
                func = matlab.io.internal.functions.FunctionStore.getFunctionByName('readtableWithImportOptions');
                T = func.validateAndExecute(filename,opts,varargin{:});
            catch ME
                throw(ME);
            end
        end

        function TT = readtimetable(filename,opts,varargin)
            if ~isa(opts,'matlab.io.ImportOptions')
                error(message('MATLAB:textio:io:OptsSecondArg','readtimetable'))
            end
            try
                func = matlab.io.internal.functions.FunctionStore.getFunctionByName('readtimetableWithImportOptions');
                TT = func.validateAndExecute(filename,opts,varargin{:});
            catch ME
                throw(ME);
            end
        end

        function A = readmatrix(filename,opts,varargin)
            if ~isa(opts,'matlab.io.ImportOptions')
                error(message('MATLAB:textio:io:OptsSecondArg','readmatrix'))
            end
            try
                func = matlab.io.internal.functions.FunctionStore.getFunctionByName('readmatrixWithImportOptions');
                A = func.validateAndExecute(filename,opts,varargin{:});
            catch ME
                throw(ME);
            end
        end

        function C = readcell(filename,opts,varargin)
            if ~isa(opts,'matlab.io.ImportOptions')
                error(message('MATLAB:textio:io:OptsSecondArg','readcell'))
            end
            try
                func = matlab.io.internal.functions.FunctionStore.getFunctionByName('readcellWithImportOptions');
                C = func.validateAndExecute(filename,opts,varargin{:});
            catch ME
                throw(ME);
            end
        end

        function varargout = readvars(filename,opts,varargin)
            if ~isa(opts,'matlab.io.ImportOptions')
                error(message('MATLAB:textio:io:OptsSecondArg','readvars'))
            end
            try
                func = matlab.io.internal.functions.FunctionStore.getFunctionByName('readvarsWithImportOptions');
                [varargout{1:nargout}] = func.validateAndExecute(filename,opts,varargin{:});
            catch ME
                throw(ME);
            end
        end

        function disp(opts)
            import matlab.io.internal.common.display.cellArrayDisp;
            name = inputname(1);
            h = matlab.internal.datatypes.DisplayHelper(class(opts));

            opts.addCustomPropertyGroups(h);
            if ~isa(opts,'matlab.io.internal.mixin.UsesStringsForPropertyValues')
                replacePropDisp(h,"VariableNames",cellArrayDisp(opts.VariableNames,false,''));
                replacePropDisp(h,"VariableTypes",cellArrayDisp(opts.VariableTypes,false,''));
                replacePropDisp(h,"SelectedVariableNames",cellArrayDisp(opts.SelectedVariableNames,false,''));
            end

            if h.usingHotlinks()
                setVarHelp = h.helpTextLink("setvaropts", class(opts) + "/setvaropts");
                getVarHelp = h.helpTextLink("getvaropts", class(opts) + "/getvaropts");
                setvartypeText = h.helpTextLink("setvartype", class(opts) + "/setvartype");

                replacePropDisp(h,"VariableOptions",...
                                getString(message('MATLAB:textio:importOptionsDisplay:ShowAll',numel(opts.VariableNames),h.propDisplayLink(name,"VariableOptions"))));
            else
                setVarHelp = "setvaropts";
                getVarHelp = "getvaropts";
                setvartypeText = "setvartype";

                replacePropDisp(h,"VariableOptions",...
                                sprintf(['[1' getString(message('MATLAB:matrix:dimension_separator')) '%d %s]'],numel(opts.VariableNames),'matlab.io.VariableImportOptions'));
            end

            % Display VariableOptions value
            appendPropDisp(h,getString( ...
                message('MATLAB:textio:importOptionsDisplay:VariableImportProperties')), ...
                           getString(message('MATLAB:textio:importOptionsDisplay:SetTypesByName', setvartypeText)));

            % Display VariableOptions sub-properties hint
            appendPropDisp(h,"VariableOptions",...
                           getString(message('MATLAB:textio:importOptionsDisplay:VarOptsSubProperties',setVarHelp,getVarHelp)));

            % Display the PreserveVariableNames property.
            replacePropDisp(h, "PreserveVariableNames", string(opts.PreserveVariableNames));

            % Display a hint to use 'preview' to preview the
            % resulting table for supported ImportOptions classes
            if isa(opts, 'matlab.io.spreadsheet.SpreadsheetImportOptions') || ...
                    isa(opts, 'matlab.io.text.DelimitedTextImportOptions') || ...
                    isa(opts, 'matlab.io.text.FixedWidthImportOptions')
                if h.usingHotlinks()
                    previewHelp = h.helpTextLink(getString(message('MATLAB:textio:importOptionsDisplay:Preview')),"matlab.io.text.TextImportOptions/preview");
                else
                    previewHelp = getString(message('MATLAB:textio:importOptionsDisplay:Preview'));
                end

                if isa(opts,'matlab.io.spreadsheet.SpreadsheetImportOptions')
                    lastProp = "VariableDescriptionsRange";
                elseif isa(opts,'matlab.io.text.DelimitedTextImportOptions') || isa(opts,'matlab.io.text.FixedWidthImportOptions')
                    lastProp = "VariableDescriptionsLine";
                end

                appendPropDisp(h,lastProp,sprintf('\n\t%s %s',...
                                                  getString(message('MATLAB:textio:io:TablePreview')),previewHelp));
                opts.modifyCustomGroups(h);
            end

            h.printToScreen("opts",false);
        end

        function obj = saveobj(obj)
            obj.var_opts = obj.VariableOptions;
        end
    end

    properties (Dependent, Access = {?matlab.io.internal.mixin.HasPropertiesAsNVPairs})
        NumVariables
    end

    methods (Hidden)
        function opts = setUnboundedSelection(opts,isUnbounded)
            opts.is_unbounded_selection = isUnbounded;
        end
        function tf = namesAreGenerated(opts)
            tf = opts.using_generated_names;
        end

        function opts = useGeneratedNames(opts,rnc)
            opts.using_generated_names = true;
            if rnc > 0 && rnc <= opts.fast_var_opts.numVars
                opts.fast_var_opts = opts.fast_var_opts.setVarNames(rnc, {'Row'});
            end
        end

        function varopts = getVarOptsStruct(opts,idx)
            varopts = opts.fast_var_opts.getVarOptsStruct(idx);
        end

    end

    methods(Access = protected)
        function s = saveToStruct(obj)
            s = struct();
            % properties defined in ImportOptions
            s.selected_vars = obj.selected_vars;
            s.is_unbounded_selection = obj.is_unbounded_selection;
            s.using_generated_names = obj.using_generated_names;
            s.fast_var_opts = obj.fast_var_opts;
            s.EmptyColumnType = obj.EmptyColumnType;

            % properties defined in MissingErrorRulesInputs
            s.ImportErrorRule = obj.ImportErrorRule;
            s.MissingRule = obj.MissingRule;

            % properties defined in PreserveVariableNamesInput
            s.PreserveVariableNames = obj.PreserveVariableNames;
        end

        function obj = loadFromStruct(obj, s)
        % properties defined in ImportOptions
            obj = trySetProp(obj, s, "selected_vars");
            obj = trySetProp(obj, s, "is_unbounded_selection");
            obj = trySetProp(obj, s, "using_generated_names");
            obj = trySetProp(obj, s, "fast_var_opts");
            obj = trySetProp(obj, s, "EmptyColumnType");

            % properties defined in MissingErrorRulesInputs
            obj = trySetProp(obj, s, "ImportErrorRule");
            obj = trySetProp(obj, s, "MissingRule");

            % properties defined in PreserveVariableNamesInput
            obj = trySetProp(obj, s, "PreserveVariableNames");
        end
    end
end

function obj = trySetProp(obj, s, prop)
% Tries to set property to the saved value.
    try
        obj.(prop) = s.(prop);
    catch ME
        % Don't warn if the property is not a field on the struct. This
        % may happen when loading an object saved in a previous release.
        if ~strcmp(ME.identifier, 'MATLAB:nonExistentField')
            warning(message('MATLAB:io:xml:saveload:IncompatiblePropertyLoad',...
                            'ImportOptions', prop));
        end
    end
end

function validateLogical(tf,param)
    if ~islogical(tf) && ~isnumeric(tf) || ~isscalar(tf)
        error(message('MATLAB:table:InvalidLogicalVal',param));
    end
end

% Copyright 2016-2024 The MathWorks, Inc.
