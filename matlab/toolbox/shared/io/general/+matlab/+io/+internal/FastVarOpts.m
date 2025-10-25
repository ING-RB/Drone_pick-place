classdef FastVarOpts < matlab.mixin.internal.Scalar
    % FastVarOpts stores the name, type, and options for importing a
    % variable from a text or spreadsheet file. The options that
    % can be specified for each variable is dictated by the variable type.
    %
    % See also: matlab.io.VariableImportOptions

    % Copyright 2019-2024 The MathWorks, Inc.

    properties(SetAccess = private, GetAccess = public)
        OptionsStruct;
        NeedsUniformCheck(1,1) logical = false;
    end
    
    properties (Dependent)
        Names
        Types
    end

    properties
        % Locale to use as the DatetimeLocale value for datetime variables
        % whose DatetimeLocale values are not stored in the OptionsStruct.
        DefaultDatetimeLocale char = matlab.internal.datetime.getDefaults('locale')
    end
    
    methods
        % -------------------------------------------------------------------------
        function obj = FastVarOpts(n,Types)
            mustBeNonnegative(n);
            if nargin < 2
                Types = repmat({'char'},n,1);
            else
                t = matlab.io.internal.supportedTypeNames();
                t{end + 1} = 'hexadecimal';
                t{end + 1} = 'binary';
                tf = any(string(Types(:))==t,2);
                if ~all(tf)
                    error(message('MATLAB:textio:io:UnsupportedConversionType',Types{find(~tf,1)}));
                end
                Types = Types(:);
                n = numel(Types);
                if ~isempty(Types)
                    obj.NeedsUniformCheck = ~all(strcmp(Types,Types{1}));
                end
            end
            Names = repmat({''},n,1);

            Options = repmat({struct},n,1);

            % OptionsStruct is a struct with three fields: Names, Types,
            % and Options. The names and types fields are cell arrays
            % containing the names and types of import variables,
            % respectively. Options is a cell array of structs that
            % describe the import options for each variable.
            %
            % NOTE: The structs within the Options cell array should not
            % have Type as a field!
            obj.OptionsStruct = struct();
            obj.OptionsStruct.Types = Types;
            obj.OptionsStruct.Names = Names;
            obj.OptionsStruct.Options = Options;
        end
        % -------------------------------------------------------------------------
        function obj = setTypes(obj,idx,newType,isHexBin)
            % Extract the property while editing, since the is a handle
            % object and validation can error based on type.
            if ~exist('isHexBin','var') 
                isHexBin = false;
            end
 
            newType = convertCharsToStrings(newType(:));
            if ~isstring(newType)
                error(message('MATLAB:textio:textio:InvalidStringOrCellStringProperty','VariableTypes'));
            end

            t = matlab.io.internal.supportedTypeNames();
            if (isHexBin)
                t{end + 1} = 'hexadecimal';
                t{end + 1} = 'binary';
            end

            t{end + 1} = 'auto';
            tf = ismember(newType,t);
            if ~all(tf)
                error(message('MATLAB:textio:io:UnsupportedConversionType',newType{find(~tf,1)}));
            end

            if isempty(idx) || isempty(newType)
                return;
            end

            C = obj.OptionsStruct.Options;

            if isstring(newType) && isscalar(newType)
                newType = repmat(newType, numel(idx), 1);
            end
            % Don't update the types or bother checking if the new type is
            % the old type.
            oldTypes = obj.OptionsStruct.Types;
            typeChanged = (newType ~= oldTypes(idx));
            for ii = 1:numel(idx)
                kk = idx(ii);
                if typeChanged(ii)
                    % Type can change, need to validate the mismatched
                    % properties are removed.
                    for f = fieldnames(C{kk})'
                        if strcmp(f,'InputFormat')
                            % datetime to duration change, this means
                            % InputFormat needs to be removed since there's
                            % no overlap between the two
                            C{kk} = rmfield(C{kk},'InputFormat');
                        elseif strcmp(f,'FillValue')
                            % Fillvalues can change when type changes,
                            % sometimes that "just works" and we can keep
                            % the old value, other times that may fail.
                            
                            if ~isCompatibleTypes(newType(ii),oldTypes(kk))
                                C{kk} = rmfield(C{kk},'FillValue');
                            end
                        else
                            % If the property doesn't exist on the new
                            % type, just drop it.
                            try
                                checkTypeSpecific(newType{ii},f)
                            catch me
                                C{kk} = rmfield(C{kk},f);
                            end
                        end
                    end
                end
            end
            obj.OptionsStruct.Options = C;
            obj.OptionsStruct.Types(idx) = cellstr(newType);
            
            % if it was already uniform and we are setting every index
            % it's still uniform
            if ~obj.NeedsUniformCheck && (~isempty(setxor(idx,1:numel(C))) || any(newType ~= newType(1)))
                obj.NeedsUniformCheck = true;
            end
        end
        % -------------------------------------------------------------------------
        function obj = setProps(obj,idx,varargin)
            
            [func,supplied] = validateVarOpts(obj,idx,varargin);
            obj = obj.assignVarOpts(func,supplied,idx);
            
        end
        % -------------------------------------------------------------------------
        function opts = getVarOpts(obj,idx)
            opts = matlab.io.TextVariableImportOptions().empty();
            C = obj.OptionsStruct.Options;
            if nargin < 2
                idx = 1:numel(C);
            else
                idx = obj.fixSelection(idx);
            end
            
            if ~obj.NeedsUniformCheck && numel(C) > 0
                % just get one and Repmat
                type = obj.OptionsStruct.Types{idx(1)};
                opts = repmat(getTypedOpts(type,C{idx(1)},obj.DefaultDatetimeLocale),1,numel(idx));
            else
                types = obj.OptionsStruct.Types;
                for kk = 1:numel(idx)
                    type = types{idx(kk)};
                    args = C{idx(kk)};
                    opts(kk) = getTypedOpts(type,args,obj.DefaultDatetimeLocale);
                end
            end
            theNames = obj.Names(idx);
            [opts(1:numel(idx)).Name] = theNames{:};
        end
        % -------------------------------------------------------------------------
        function s = getVarOptsStruct(obj,idx,setnames)
            % s = opts.getVarOptsStruct() gets all the struct options with
            %     default vales, names which have been set, and default
            %     names for any variables without a set names.
            %
            % s = opts.getVarOptsStruct(idx,setnames) gets the struct
            %     options with defaults values. If SETNAMES = true, the names
            %     are copied to the struct, otherwise, the names are empty.
            %
            
            C = obj.OptionsStruct.Options;
            if nargin < 2
                idx = 1:numel(C);
            else
                idx = obj.fixSelection(idx);
            end
            n = numel(idx);
            types = obj.OptionsStruct.Types;
            if ~obj.NeedsUniformCheck && numel(idx) > 0
                % Uniform Options, get the first, and replicate it.
                s = repmat({getOptsStructWithDefaults(types{idx(1)},C{idx(1)},obj.DefaultDatetimeLocale)},1,n);
            else
                % get all the options; they might be uniform, might not.
                s = cell(1,n);
                for ii = 1:n
                    s{ii} = getOptsStructWithDefaults(types{idx(ii)},C{idx(ii)},obj.DefaultDatetimeLocale);
                end
            end
            if nargin > 2 && setnames
                % Set the names, obj.Names generates the default
                % Var1,...,VarN names in place.
                names = obj.Names;
                for ii = 1:n
                    s{ii}.Name = names{idx(ii)};
                end
            end
        end
        % -------------------------------------------------------------------------
        function isUniform = isUniformOptions(obj,idx)
            % isUniform = obj.isUniformOptions(idx) returns true if all the
            % options in the idx indices are the same (ignoring names)
            %
            % Note: This function is optimized to return an early false, and to
            % return true when no modifications have been made to the
            % options.
            
            isUniform = true;
            n = numel(obj.OptionsStruct.Types);
            if obj.NeedsUniformCheck && n > 1
                % Check the types are the same first.
                if nargin < 2
                    idx = 1:n;
                else
                    idx = obj.fixSelection(idx);
                end
                types = obj.Types;
                if ~all(strcmp(types{idx(1)},types(idx)))
                    isUniform = false;
                    return; % Don't bother checking properties.
                end
                
                % Check all the non-default settings, C only contains the
                % struct with fields set by the user; they may be
                % different, but there might be cases where a non-defualt
                % was set on the whole array.
                
                C = obj.getVarOptsStruct(idx,false);
                for ii = 1:numel(C)
                    if ~isequaln(C{1},C{ii})
                        isUniform = false;
                        return; % error early
                    end
                end
            end
            % Return true if we made it this far.
        end
        % -------------------------------------------------------------------------
        function names = get.Names(obj)
            names = obj.OptionsStruct.Names;
            if isempty(names)
                names = {};
            else
                isEmptyName = (names == "");
                % Only generate custom names on demand. And only modify the custom names to make them unique, not the prescribed names.
                names(isEmptyName) = matlab.lang.makeUniqueStrings(compose('Var%d',find(isEmptyName)),names(~isEmptyName));
            end
            if isempty(names)
                names = cell(0, 0);
            end
        end
        % -------------------------------------------------------------------------
        function t = get.Types(obj)
            t = obj.OptionsStruct.Types;
            if isempty(t)
                t = cell(0, 0);
            end
        end
        % -------------------------------------------------------------------------
        function obj = set.Names(obj,rhs)
            rhs = convertCharsToStrings(rhs);
            % Need to set the number of varnames correctly
            
            if numel(rhs) ~= numel(obj.OptionsStruct.Types)
                error(message('MATLAB:table:IncorrectNumberOfVarNames'));
            end
            obj.OptionsStruct.Names = cellstr(rhs(:));
        end
        % -------------------------------------------------------------------------
        function obj = set.Types(obj,rhs)
            if numel(rhs) ~= numel(obj.OptionsStruct.Types)
                error(message('MATLAB:textio:io:ExpectedCellStrSize',numel(obj.OptionsStruct.Types)));
            end
            obj = obj.setTypes(1:numel(obj.OptionsStruct.Types),rhs);
        end
        %--------------------------------------------------------------------------
        function obj = set.DefaultDatetimeLocale(obj, dateLocale)
            newLocale = matlab.internal.datetime.verifyLocale(dateLocale);
            % Update existing datetime variables whose DatetimeLocale
            % values are not set to preserve the old locale
            obj = obj.setUnspecifiedDatetimeLocale(obj.DefaultDatetimeLocale);
            obj.DefaultDatetimeLocale = newLocale;
        end

        % -------------------------------------------------------------------------
        function selection = fixSelection(obj,selection)
            % Fix the selection from text array of names to numeric selection
            % or validate the numeric selection.
            selection = convertCharsToStrings(selection);
            if isstring(selection)
                selection = obj.getNumericSelection(selection);
            elseif isnumeric(selection)
                if ~all(selection > 0 & isfinite(selection) & floor(selection)==selection & selection <= numel(obj.OptionsStruct.Types))
                    error(message('MATLAB:textio:io:BadNumericSelection'));
                end
            elseif islogical(selection)
                selection = find(selection);
            else
                error(message('MATLAB:textio:io:BadSelectionInput'));
            end
        end
        % -------------------------------------------------------------------------
        function idx = getNumericSelection(obj,selection)
            % selection can be string array, cellstr, or char-vector; make
            % it a string array for consistency
            selection = convertCharsToStrings(selection);
            if isscalar(selection) && strcmp(selection,':')
                idx = 1:numel(obj.OptionsStruct.Types);
            else
                % Want "VarN" as part of expected names
                expectedNames = obj.Names;
                logicalMask = (expectedNames == selection(:)');
                if any(~any(logicalMask,1))
                    % Unknown VarName
                    idx = find(~any(logicalMask,1),1);
                    error(message('MATLAB:textio:io:UnknownVarName',selection{idx}));
                end
                
                idx = zeros(1,size(logicalMask,2));
                for k = 1:size(logicalMask,2)
                    idx(k) = find(logicalMask(:,k));
                end
            end
        end
        % -------------------------------------------------------------------------
        function obj = addVars(obj,num,types)
            if nargin < 3
                types = repmat({'char'},num,1);
            end
            types = convertStringsToChars(types);
            endObj = matlab.io.internal.FastVarOpts(num,types);
            obj.OptionsStruct.Types = [obj.OptionsStruct.Types; endObj.OptionsStruct.Types];
            obj.OptionsStruct.Names = [obj.OptionsStruct.Names; endObj.OptionsStruct.Names];
            obj.OptionsStruct.Options = [obj.OptionsStruct.Options; endObj.OptionsStruct.Options];
            newTypes = obj.Types;
            if ~obj.NeedsUniformCheck && all(strcmp(newTypes{1},newTypes))
                obj.NeedsUniformCheck = false;
            end
        end
        % -------------------------------------------------------------------------
        function obj = removeVars(obj,idx)
            idx = obj.fixSelection(idx);
            obj.OptionsStruct.Types(idx, :) = [];
            obj.OptionsStruct.Names(idx, :) = [];
            obj.OptionsStruct.Options(idx, :) = [];
        end
        % -------------------------------------------------------------------------
        function out = numVars(obj)
            % Brief : return the number of variables
            % the fastVarOpts holds
            % e.g
            % a = matlab.io.internal.FastVarOpts(1)
            % a.numVars == 1
            % b = matlab.io.internal.FastVarOpts(3)
            % b.numVars == 3
            out = numel(obj.OptionsStruct.Types);
        end
        % -------------------------------------------------------------------------
        function tf = isequal(varargin)
            tf = isequaln(varargin{:});
        end
        % -------------------------------------------------------------------------
        function tf = isequaln(varargin)
            tf = true;
            opts = varargin{1};
            if ~isa(opts, "matlab.io.internal.FastVarOpts")
                tf = false;
                return
            end
            opts_struct = opts.getVarOptsStructTyedFillValue(':', true);
            for i = 2:nargin
                toCompare = varargin{i};
                if ~isa(toCompare, "matlab.io.internal.FastVarOpts")
                    tf = false;
                    return
                end
                if ~isequaln(opts_struct, toCompare.getVarOptsStructTyedFillValue(':', true))
                    tf = false;
                    return;
                end
            end
        end
    end
    
    methods(Static)
        function fvo = fromFullVarOpts(opts)
            % Construct a FastVarOpts from a full object array.
            fvo = matlab.io.internal.FastVarOpts(numel(opts));
            os = fvo.OptionsStruct;
            
            for i = 1:numel(opts)
                st = makeOptsStruct(opts(i));
                os.Names{i} = st.Name;
                os.Types{i} = st.Type;
                st.FillValue = opts(i).FillValue;
                if strcmp(st.Type, 'datetime') && isdatetime(st.FillValue)
                    st.FillValue = datetime.toMillis(st.FillValue);
                end   
                if strcmp(st.Type, 'duration') && isduration(st.FillValue)
                    st.FillValue = milliseconds(st.FillValue);
                end   
                % store categorical variables as char arrays
                if strcmp(st.Type, 'categorical')
                    st.FillValue = char(st.FillValue);
                end
                if any(strcmp(st.Type,["char","string"])) && isequal(opts(i).FillValue_,[])
                    st = rmfield(st,"FillValue");
                end
                st = rmfield(st,["Name","Type"]);
                os.Options{i} = st;
            end
            % Var opts may have non-unique names, so make them unique on constuction
            nonEmpty = (strlength(os.Names) > 0);
            os.Names(nonEmpty) = matlab.lang.makeUniqueStrings(os.Names(nonEmpty));
            fvo.OptionsStruct = os;
            fvo.NeedsUniformCheck = true;
        end
    end
    
    methods (Access = {?matlab.io.internal.functions.SetVarOpts,...
            ?matlab.io.internal.FastVarOpts})

        function [func,supplied,idx] = validateVarOpts(obj,idx,args)
            idx = obj.fixSelection(idx);
            func = matlab.io.internal.functions.FunctionStore.getFunctionByName('setvaropts');
            % Just want the validation, not the assignment that happens in
            % the execute function
            [func,supplied] = func.validate(func.Options,':',args{:});
        end
        
        
        function obj = assignVarOpts(obj,func,supplied,idx)
            persistent propnames
            if isempty(propnames)
                propnames = fieldnames(supplied);
                propnames(1:2) = []; % remove the required args.
            end
            supplied = struct2cell(supplied);
            props = propnames([supplied{3:end}]);
            obj = obj.assignVarOptsProps(func, props, idx);
        end
    end
    
    methods (Access = {?matlab.io.internal.FastVarOpts,...
            ?matlab.io.internal.functions.DetectImportOptions})
        function obj = assignVarOptsProps(obj, func, propnames, idx)
            idx = obj.fixSelection(idx);
            % Extract the property while editing, since the is a handle
            % object and validation can error based on type.
            C = obj.OptionsStruct.Options;
            types = obj.Types;
            propnames = convertCharsToStrings(propnames);
            for ii = 1:numel(propnames)
                n = propnames(ii);
                idx = sort(idx);
                if ~obj.NeedsUniformCheck &&  ~isequal(idx, 1:numel(C))
                    obj.NeedsUniformCheck = true;
                end
                for jj = 1:numel(idx)
                    t = types{idx(jj)};
                    checkTypeSpecific(t,n)
                    if strcmp(n,'Name')
                        % Store the names separately
                        obj.OptionsStruct.Names{idx(jj)} = func.Name;
                    elseif strcmp(n,'FillValue')
                        if strcmp(t,'categorical') && isfield(C{idx(jj)}, 'Categories')
                            % create a CategoricalVariableImportOptions
                            % with the appropriate Categories. The Ordinal
                            % and Protected properties are not required to
                            % validate the fill value.
                            vo = matlab.io.CategoricalVariableImportOptions(Categories=C{idx(jj)}.Categories);
                            vo.FillValue = func.FillValue;
                            C{idx(jj)}.FillValue = char(vo.FillValue); % always set to char
                        else
                            C{idx(jj)}.FillValue = validateFill(t,func.FillValue);
                        end
                    elseif strcmp(n,'Categories')
                        % If the new Categories value is empty, no need to
                        % verify the FillValue is one of the categories.
                        if ~isempty(func.Categories) && isfield(C{idx(jj)},'FillValue')
                            fill = C{idx(jj)}.FillValue;
                            if ~any(strcmp(string(fill),func.Categories))
                                C{idx(jj)}.FillValue = [];
                            end
                        end
                        C{idx(jj)}.Categories = func.Categories;
                    elseif strcmp(n,'Protected')
                        if isfield(C{idx(jj)},'Ordinal') && C{idx(jj)}.Ordinal && ~func.Protected
                            error(message('MATLAB:categorical:UnprotectedOrdinal'));
                        end
                        C{idx(jj)}.Protected = func.Protected;
                    elseif strcmp(n,'InputFormat')
                        % Input Format has different validation depending
                        % on whether or not it's duration or datetime.
                        if t == "duration"
                            vo = matlab.io.DurationVariableImportOptions('InputFormat',func.InputFormat);
                        elseif t == "datetime"
                            vo = matlab.io.DatetimeVariableImportOptions('InputFormat',func.InputFormat);
                        end
                        C{idx(jj)}.InputFormat = vo.InputFormat;
                    elseif n ~= "Type" 
                        % If one of the properties provided to setvaropts was
                        % "Type", the OptionsStruct Types cell array will have
                        % already been updated. Do not add Type as a field
                        % to the variable options struct.
                        C{idx(jj)}.(n) = func.(n);
                    end
                end
            end
            % Assign the options back into the struct
            obj.OptionsStruct.Options(idx) = C(idx);
        end                    
    end

    methods(Access = private)
        function s = getVarOptsStructTyedFillValue(obj, varargin)
            % Gets the struct options with the FillValues set to a
            % specific datatype for each variable type.
            s = obj.getVarOptsStruct(varargin{:});
            for ii = 1:numel(s)
                type = s{ii}.Type;
                fill = s{ii}.FillValue;
                switch type
                    case {'uint8','uint16','uint32','uint64','int8','int16','int32','int64','double','single'}
                        s{ii}.FillValue = cast(fill, type);
                    case 'char'
                        if isnumeric(fill) % default value is []
                            s{ii}.FillValue = '';
                        else
                            s{ii}.FillValue = char(fill);
                        end
                    case 'string' % default value is []
                        if isnumeric(fill)
                            s{ii}.FillValue = "";
                        else
                            s{ii}.FillValue = string(fill);
                        end
                    case 'datetime'
                        if isdatetime(fill) % convert to numerical representation
                            s{ii}.FillValue = datetime.toMillis(fill);
                        end
                    case 'duration'
                        if isduration(fill) % convert to numerical representation
                            s{ii}.FillValue = milliseconds(fill);
                        end
                    case 'categorical'
                        vopts = s{ii};
                        if isempty(fill) || strcmp(fill, categorical.undefLabel) % default is empty char array
                            s{ii}.FillValue = categorical(NaN);
                        elseif isempty(vopts.Categories)
                            s{ii}.FillValue = categorical({fill});
                        else
                            [~,id] = ismember(char(fill),vopts.Categories);
                            s{ii}.FillValue = categorical(id,1:numel(vopts.Categories),...
                                vopts.Categories, 'Ordinal', vopts.Ordinal,...
                                'Protected', vopts.Protected);
                        end
                    case 'logical' % no-op
                    otherwise
                        assert(false);
                end
            end
        end

        function obj = setUnspecifiedDatetimeLocale(obj, locale)
            idx = find(obj.OptionsStruct.Types == "datetime");
            for ii = reshape(idx, 1, []) % must iterate over a row vector
                if ~isfield(obj.OptionsStruct.Options{ii}, "DatetimeLocale")
                    obj.OptionsStruct.Options{ii}.DatetimeLocale = locale;
                end
            end
        end
    end

    methods(Hidden, Access = {...
            ?matlab.io.ImportOptions,...
            ?matlab.unittest.TestCase,...
            ?matlab.io.internal.functions.DetectImportOptionsSpreadsheet,...
            ?matlab.io.internal.shared.HexBinaryType, ...
            ?matlab.io.internal.functions.ReadMatrixWithImportOptions})

        function obj = setVarOpts(obj, idx, props, values)
            % sets variable options without validation.
            for ii = 1:numel(idx) 
                obj.OptionsStruct.Options{idx(ii)}.(props{ii}) = values{ii};
            end
        end

        function obj = setVarNames(obj, idx, names)
            % sets variable names without validation.
             obj.OptionsStruct.Names(idx) = names;
        end
    end

    methods(Hidden)
        function s = saveobj(obj)
            % Creates struct used to save FastVarOpts objects in a MAT
            % file.
            s = struct();
            s.version = 2;
            s.NeedsUniformCheck = obj.NeedsUniformCheck;
            s.Types = obj.OptionsStruct.Types;
            s.Names = obj.OptionsStruct.Names;
            s.Options = obj.OptionsStruct.Options;
            s.DefaultDatetimeLocale = obj.DefaultDatetimeLocale;
        end
    end

    methods(Static, Hidden)
        function obj = loadobj(s)
            % Loads FastVarOpts objects from MAT files.
            assert(isstruct(s));
            obj = matlab.io.internal.FastVarOpts(numel(s.Options));
            obj.NeedsUniformCheck = s.NeedsUniformCheck;
            os = obj.OptionsStruct;
            for ii = 1:numel(s.Options)
                type = s.Types{ii};
                opts = s.Options{ii};
                
                if isfield(opts, "Type")
                    % To avoid having to keep two Types properties in sync,
                    % remove Type as a property on opts if it is a field.
                    opts = rmfield(opts, "Type");
                end

                % finds all unknown properties in the options struct
                [unknownProps, unknownType] = getUnknownPropertiesByType(type, fields(opts)');
                
                if ~unknownType % valid variable type
                    opts = rmfield(opts, unknownProps);
                    os.Types{ii} = type;
                    os.Names{ii} = s.Names{ii};
                    os.Options{ii} = opts;
                else
                    % For unknown variable types, convert type into char
                    % and keep the Name, TreatAsMissing, QuoteRule,
                    % Prefixes, Suffixes and EmptyFieldRule properties,
                    % which are universal to all variable import options
                    props = ["TreatAsMissing", "QuoteRule", "Prefixes",...
                        "Suffixes", "EmptyFieldRule"];
                    props = props(isfield(opts, props));
                    vopts = struct();
                    for jj = 1:numel(props)
                        vopts.(props(jj)) = opts.(props(jj));
                    end
                    os.Types{ii} = 'char';
                    os.Names{ii} = s.Names{ii};
                    os.Options{ii} = vopts;
                    warning(message('MATLAB:textio:textio:LoadedUnknownType', type));
                end
            end
           obj.OptionsStruct = os;
           if s.version >= 2
                obj.DefaultDatetimeLocale = s.DefaultDatetimeLocale;
           end
        end
    end
end

% -------------------------------------------------------------------------
function [unknownProps, unknownType] = getUnknownPropertiesByType(t, opts)
% Returns a string array containing all of the unknown options in the
% option struct that was loaded from a MAT file. If more options are
% added
typeProperties = getTypeSpecificProperties();
unknownType = false;
switch t
    case {'uint8','uint16','uint32','uint64','int8','int16','int32','int64','double','single'}
        unknownProps = opts(~ismember(opts, typeProperties.numeric));
    case 'datetime'
        unknownProps = opts(~ismember(opts, typeProperties.datetime));
    case 'duration'
        unknownProps = opts(~ismember(opts, typeProperties.duration));
    case 'logical'
        unknownProps = opts(~ismember(opts, typeProperties.logical));
    case 'categorical'
        unknownProps = opts(~ismember(opts, typeProperties.categorical));
    case {'char','string'}
        unknownProps = opts(~ismember(opts, typeProperties.text));
    otherwise
        unknownProps = {};
        unknownType = true;
end
end

% -------------------------------------------------------------------------
function fill = validateFill(tnew,fill)
import matlab.io.*
switch tnew
    case {'uint8','uint16','uint32','uint64','int8','int16','int32','int64','double','single'}
        opts = NumericVariableImportOptions('FillValue',fill);
        fill = opts.FillValue;
    case 'datetime'
        opts = DatetimeVariableImportOptions('FillValue',fill);
        fill = opts.FillValue;
        fill = datetime.toMillis(fill);
    case 'duration'
        opts = DurationVariableImportOptions('FillValue',fill);
        fill = opts.FillValue;
        fill = milliseconds(fill);
    case 'logical'
        opts = LogicalVariableImportOptions('FillValue',fill);
        fill = opts.FillValue;
    case 'categorical'
        opts = CategoricalVariableImportOptions('FillValue',fill);
        fill = char(opts.FillValue_);
    case {'char','string'}
        opts = TextVariableImportOptions('Type',tnew,'FillValue',fill);
        fill = opts.FillValue_;
        if ~isnumeric(fill) && ~ismissing(fill)
            fill = char(fill);
        end
end
end

% -------------------------------------------------------------------------
function tf = isCompatibleTypes(tnew,told)
import matlab.io.*
if strcmp(tnew,told)
    tf = true;
elseif strcmp(told,{'categorical','datetime','duration','logical'})
    tf = false;
else
    types = {char(told),char(tnew)};
    tf = all(ismember(types,{'uint8','uint16','uint32','uint64',...
        'int8','int16','int32','int64',...
        'double','single'}),'all') ...
        || all(ismember(types,{'char','string'}),'all');
end
end
% -------------------------------------------------------------------------
function opts = getTypedOpts(t,args, defaultDatetimeLocale)
import matlab.io.*
% FillValue may be stored in the low level representation for each type and
% valid values may depend on the other args, so assigning it separately
% avoids order-or-eval issues.
usingFillValue = isfield(args,'FillValue');
if usingFillValue
    fv = args.FillValue;
    args = rmfield(args,'FillValue');
end
userSuppliedType = isfield(args,'Type');
if userSuppliedType
    args = rmfield(args,'Type');
end
switch t
    case {'uint8','uint16','uint32','uint64','int8','int16','int32','int64','double','single','auto'}
        opts = NumericVariableImportOptions('Type',t,args);
        if usingFillValue, opts.FillValue = fv; end
    case 'datetime'
        opts = DatetimeVariableImportOptions(args);
        if usingFillValue
            if ismissing(fv)
                fv = datetime.fromMillis(NaN + 0i);
            elseif ~isdatetime(fv)
                fv = datetime.fromMillis(fv);
            end
            if strcmp(opts.DatetimeFormat, 'preserveinput')
                % If DatetimeFormat='preserveinput' AND InputFormat is not
                % empty, set the Format property of the FillValue to the
                % InputFormat value.
                if ~isempty(opts.InputFormat)
                    fv.Format = opts.InputFormat;
                end
            elseif ~strcmp(opts.DatetimeFormat, 'default')
                % If DatetimeFormat != 'default' (i.e. it's set
                % to either a custom format or 'defaultdate'), set the
                % Format property of the FillValue to the DatetimeFormat
                % value.  When DatetimeFormat='default', there's no need
                % to set Format property of the FillValue; the Format is
                % already set to the default value.
                fv.Format = opts.DatetimeFormat;
            end
            opts.FillValue = fv;
        end
        if ~isfield(args, 'DatetimeLocale')
            opts.DatetimeLocale = defaultDatetimeLocale;
        end
    case 'duration'
        opts = DurationVariableImportOptions(args);
        if usingFillValue
            if ~isduration(fv)
                fv = milliseconds(fv);
            end
            if ~strcmp(opts.DurationFormat, 'default')
                fv.Format = opts.DurationFormat;
            end
            opts.FillValue = fv;
        end
    case 'logical'
        opts = LogicalVariableImportOptions(args);
        if usingFillValue, opts.FillValue = fv; end
    case 'categorical'
        opts = CategoricalVariableImportOptions(args);
        if usingFillValue
            % There's never a reason this should fail unless the categories
            % were changed after setting the FillValue, in that case, just
            % assign '', which is Undefined.
            try
                opts.FillValue = fv;
            catch
                opts.FillValue = '';
            end
        end
    case {'char','string'}
        opts = TextVariableImportOptions('Type',t,args);
        if usingFillValue
            opts.FillValue_ = fv;
        end
end
end
% -------------------------------------------------------------------------
function s = getOptsStructWithDefaults(t,sCustom, defaultDatetimeLocale)
import matlab.io.*
persistent defaults
if isempty(defaults)
    defaults.numeric     = makeOptsStruct(matlab.io.NumericVariableImportOptions);
    defaults.datetime    = makeOptsStruct(matlab.io.DatetimeVariableImportOptions');
    defaults.datetime.FillValue = complex(NaN,0);
    defaults.duration    = makeOptsStruct(matlab.io.DurationVariableImportOptions');
    defaults.categorical = makeOptsStruct(matlab.io.CategoricalVariableImportOptions');
    defaults.text        = makeOptsStruct(matlab.io.TextVariableImportOptions');
    defaults.logical     = makeOptsStruct(matlab.io.LogicalVariableImportOptions');
end

switch t
    % FillValues should be stored in the internal format
    case {'uint8','uint16','uint32','uint64','int8','int16','int32','int64','double','single','auto'}
        s = defaults.numeric;
        s.Type = t;
        if t == "auto"
            s.FillValue = 0;
        else
            s.FillValue = cast(s.FillValue,t);
        end
    case 'datetime'
        s = defaults.datetime;
        if isfield(sCustom,'FillValue') && isdatetime(sCustom.FillValue)
            sCustom.FillValue = datetime.toMillis(sCustom.FillValue);
        end
        if ~isfield(sCustom, 'DatetimeLocale')
            sCustom.DatetimeLocale = defaultDatetimeLocale;
        end
    case 'duration'
        s = defaults.duration;
        if isfield(sCustom,'FillValue') && isduration(sCustom.FillValue)
            sCustom.FillValue = milliseconds(sCustom.FillValue);
        end
    case 'logical'
        s = defaults.logical;
    case 'categorical'
        s = defaults.categorical;
        % Ordinal Implies Protected
        
        if isfield(sCustom,'Ordinal') && sCustom.Ordinal
            s.Protected = true;
            if isfield(sCustom, 'Protected')
                sCustom = rmfield(sCustom, 'Protected');
            end
        end
    case 'char'
        s = defaults.text;
        s.FillValue = zeros(0);
    case 'string'
        s = defaults.text;
        s.Type = t;
        s.FillValue = string(missing);
end
for field = fieldnames(sCustom)'
    s.(field{:}) = sCustom.(field{:});
end

% cannot create Undefined categorical value with char array '<undefined>'
if strcmp(t, 'categorical') && strcmp(s.FillValue, categorical.undefLabel)
    s.FillValue = '';
end

end
% -------------------------------------------------------------------------
function checkTypeSpecific(t,n)
typespecific = getTypeSpecificProperties();
try
    switch t
        case {'uint8','uint16','uint32','uint64','int8','int16','int32','int64','double','single','auto'}
            assert(any(strcmp(n,typespecific.numeric)));
        case 'datetime'
            assert(any(strcmp(n,typespecific.datetime)));
        case 'duration'
            assert(any(strcmp(n,typespecific.duration)));
        case 'logical'
            assert(any(strcmp(n,typespecific.logical)));
        case 'categorical'
            assert(any(strcmp(n,typespecific.categorical)));
        case {'char','string'}
            assert(any(strcmp(n,typespecific.text)));
    end
catch
    error(message('MATLAB:textio:io:OptionNotAvailableForType',n))
end
end

function props = getTypeSpecificProperties()
persistent typespecific
if isempty(typespecific)
    typespecific.numeric     = properties('matlab.io.NumericVariableImportOptions');
    typespecific.datetime    = properties('matlab.io.DatetimeVariableImportOptions');
    typespecific.duration    = properties('matlab.io.DurationVariableImportOptions');
    typespecific.categorical = properties('matlab.io.CategoricalVariableImportOptions');
    typespecific.text        = properties('matlab.io.TextVariableImportOptions');
    typespecific.logical     = properties('matlab.io.LogicalVariableImportOptions');
end
props = typespecific;
end

