classdef VariableImportOptions < matlab.io.internal.mixin.HasPropertiesAsNVPairs ...
        & matlab.io.internal.common.display.ObjectArrayDisp ...
        & matlab.mixin.Heterogeneous ...
        & matlab.io.internal.shared.VarOptsInputs
    %VARIABLEIMPORTOPTIONS Options for importing a variable from a file
    %
    %   VariableImportOptions Properties:
    %               Name - The name of the variable on import
    %               Type - The data type of the variable on import
    %          FillValue - A scalar value to fill missing or unconvertible data
    %     TreatAsMissing - Text which is used in a file to represent missing
    %                      data, e.g. 'NA'
    %     EmptyFieldRule - How to treat empty field data
    %          QuoteRule - How to treat quoted text.
    %           Prefixes - Prefix characters to be removed from variable on
    %                      import
    %           Suffixes - Suffix characters to be removed from variable on
    %                      import
    %
    % See also
    %   readtable, datastore, matlab.io.spreadsheet.SpreadsheetImportOptions
    %   matlab.io.TextVariableImportOptions
    %   matlab.io.NumericVariableImportOptions
    %   matlab.io.LogicalVariableImportOptions
    %   matlab.io.DatetimeVariableImportOptions
    %   matlab.io.DurationVariableImportOptions
    %   matlab.io.CategoricalVariableImportOptions
    
    % Copyright 2016-2022 The MathWorks, Inc.
    methods (Static, Sealed, Access = protected)
        function elem = getDefaultScalarElement()
            elem = matlab.io.TextVariableImportOptions();
        end
    end
    
    methods (Sealed, Access=?matlab.io.ImportOptions)
        function obj = overrideType(obj,idx,types)
            tf = ismember(types,matlab.io.internal.supportedTypeNames());
            
            if ~all(tf)
                error(message('MATLAB:textio:io:UnsupportedConversionType',types{find(~tf,1)}));
            end
            % Convert the selection to the requested types.
            for i = 1:numel(idx)
                obj(idx(i)) = convertOptsToType(obj(idx(i)),types{i});
            end
        end
    end
    
    % For child class to do custom display
    methods (Abstract, Access = protected)
        [type_specific,group_name] = getTypedPropertyGroup(obj);
        tf = compareVarProps(a,b);
    end
    
    methods (Sealed,Static,Hidden)
        function obj = getTypedOptionsByName(newType)
            switch newType
                case {'double','single','int8','uint8','int16','uint16','int32','uint32','int64','uint64'}
                    obj = matlab.io.NumericVariableImportOptions('Type',newType);
                case {'char','string'}
                    obj = matlab.io.TextVariableImportOptions('Type',newType);
                case 'datetime'
                    obj = matlab.io.DatetimeVariableImportOptions();
                case 'duration'
                    obj = matlab.io.DurationVariableImportOptions();
                case 'categorical'
                    obj = matlab.io.CategoricalVariableImportOptions();
                case 'logical'
                    obj = matlab.io.LogicalVariableImportOptions();
                otherwise
                    assert(false);
            end
        end
    end
    
    methods (Access = private)
        function obj = convertOptsToType(obj,type)
            % Set the shared properties
            persistent sharedProperties
            if isempty(sharedProperties)
                meta = ?matlab.io.VariableImportOptions;
                propList = meta.PropertyList;
                ispublic = false(1,numel(propList));
                for i = 1:numel(propList)
                    ispublic(i) = ischar(propList(i).GetAccess) && strcmp('public',propList(i).GetAccess);
                end
                sharedProperties = setdiff({propList(ispublic).Name},["Type","FillValue"]);
            end
            
            try
                obj.Type = type;
            catch
                oldobj = obj;
                % First get an object of the new type
                obj = matlab.io.VariableImportOptions.getTypedOptionsByName(type);
                % Assign old properties into new properties.
                for p = sharedProperties
                    obj.(p{:}) =  oldobj.(p{:});
                end
            end
        end
    end
    
    methods (Hidden)
        function s = makeOptsStruct(opts)
            
            s.Name = opts.Name_;
            s.Type = opts.Type_;
            s.FillValue = opts.getFillValue(opts.FillValue_);
            s.EmptyFieldRule = opts.EmptyFieldRule;
            s = opts.addTypeSpecificOpts(s);
        end
    end
    
    properties (Constant, Access = 'protected')
        ProtectedNames = ["Name" "Type" "FillValue"];
    end
    
    methods(Static, Hidden)
        function obj = loadobj(s)
            % Loads VariableImportOptions object from a MAT file.
            if isstruct(s)
                obj = matlab.io.VariableImportOptions.getTypedOptionsByName(s.Type);
                
                % Get a list of properties
                typedSpecifcProps = obj.getTypeSpecificProperties();
                commonProps = ["Name", "TreatAsMissing", "QuoteRule",...
                    "Prefixes", "Suffixes", "EmptyFieldRule"];
                
                if ~isa(obj, 'matlab.io.NumericVariableImportOptions')
                    commonProps = [commonProps "FillValue"];
                end
                
                props = [commonProps typedSpecifcProps];
                
                if isfield(s, "Name_")
                    s.Name = s.Name_;
                    s = rmfield(s, "Name_");
                end
                
                % if name is the empty string, do not set the Name property
                % because setting Name to "", '' explicitly will error
                name = convertCharsToStrings(s.Name);
                if isstring(name) && isscalar(name) && strlength(name) == 0
                    props = props(2:end); % removes "Name" from the props list
                end
                
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
                
                % FillValue for numeric values should not be cast into a
                % different numeric type during load
                if isa(obj, 'matlab.io.NumericVariableImportOptions')
                    try
                        if isfield(s, "FillValue_")
                            obj.FillValue = s.FillValue_;
                        else
                            obj.FillValue = s.FillValue;
                        end
                    catch ME
                        if ~strcmp(ME.identifier, 'MATLAB:nonExistentField')
                            warning(ME.identifier, '%s', ME.message);
                        end
                    end
                end
            else
                % saved as an object instead of as a struct.
                obj = s;
                % explictly set FillValue to store it as the appropriate
                % type if obj is not a NumericVariableImportOptions
                if ~isa(obj, 'matlab.io.NumericVariableImportOptions')
                    obj.FillValue = s.FillValue;
                end
            end
        end
    end
    
    methods(Static, Abstract, Access = protected)
        props = getTypeSpecificProperties();
    end
    
    methods (Sealed, Access = 'protected')
        function DispInfo = getDispInfo(obj)
            
            propNames = {'Name';'Type';'FillValue';'TreatAsMissing';'EmptyFieldRule'; ...
                'QuoteRule';'Prefixes';'Suffixes'};
            
            DispInfo.Data = struct(propNames{1},{obj.Name},...
                propNames{2},{obj.Type},...
                propNames{3},{obj.FillValue}, ...
                propNames{4},{obj.TreatAsMissing},...
                propNames{5},{obj.EmptyFieldRule}, ...
                propNames{6},{obj.QuoteRule},...
                propNames{7},{obj.Prefixes},...
                propNames{8},{obj.Suffixes});
            
            
            DispInfo.ShortName = "VariableImportOptions";
            DispInfo.LongName = "matlab.io.VariableImportOptions";
            DispInfo.Title = "Variable Options";
            
            strHelpGetvaropts = '<a href="matlab:helpPopup getvaropts" style="font-weight:regular">getvaropts</a>';
            DispInfo.Footer = sprintf(['\n\t', getString(message('MATLAB:textio:io:GetvaroptsLink')), ' ',strHelpGetvaropts, '\n']);
        end
        
        function propgrp = getPropertyGroups(obj)
            if ~isscalar(obj)
                propgrp = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else
                props.Name            = obj.Name;
                props.Type            = obj.Type;
                props.FillValue       = obj.FillValue;
                props.TreatAsMissing  = obj.TreatAsMissing;
                props.QuoteRule       = obj.QuoteRule;
                props.Prefixes        = obj.Prefixes;
                props.Suffixes        = obj.Suffixes;
                props.EmptyFieldRule  = obj.EmptyFieldRule;
                
                propgrp(1) = matlab.mixin.util.PropertyGroup(props,'Variable Properties:');
                
                [type_specific,group_name] = obj.getTypedPropertyGroup();
                
                propgrp(2) = matlab.mixin.util.PropertyGroup(type_specific,group_name);
            end
        end
        
        function h = getHeader(obj)
            h = getHeader@matlab.mixin.CustomDisplay(obj);
        end
        
        function f = getFooter(obj)
            f = getFooter@matlab.mixin.CustomDisplay(obj);
        end
        
        function displayEmptyObject(obj)
            displayEmptyObject@matlab.mixin.CustomDisplay(obj);
        end
        
        function C = postProcessFields(~,C,s)
            % replace <missing> with actual values
            for ii = 1 : size(C,2)
                if isempty(s(ii).FillValue)
                    C(3,ii) = "";
                elseif isa(s(ii).FillValue,"string") && ismissing(s(ii).FillValue)
                    C(3,ii) = sprintf("<missing>");
                elseif isa(s(ii).FillValue,'logical') || isnumeric(s(ii).FillValue)
                    C(3,ii) = sprintf("%u",s(ii).FillValue);
                else
                    C(3,ii) = sprintf("%s",s(ii).FillValue);
                end
            end
        end
    end
end
