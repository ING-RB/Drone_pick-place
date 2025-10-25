classdef (Sealed) CustomProperties < matlab.mixin.CustomDisplay & matlab.mixin.internal.Scalar & matlab.internal.datatypes.saveLoadCompatibility
    %CUSTOMPROPERTIES Container for custom properties of a table/timetable.
    %   CUSTOMPROPERTIES can contain both per-variable and per-table metadata that
    %   is associated with a table or timetable. Access in a table via
    %   t.Properties.CustomProperties. Add new CUSTOMPROPERTIES by using the ADDPROP
    %   function on a particular table.
    %
    %   See also: TABLE, TIMETABLE, ADDPROP, RMPROP.
    
    %   Copyright 2018-2021 The MathWorks, Inc.
    
    properties (Hidden)
        perTableProps (1,1) struct = struct()
        perVarProps (1,1) struct = struct()
    end
    
    methods (Access = {?tabular, ?matlab.tabular.TabularProperties,?matlab.unittest.TestCase})
        function this = CustomProperties(perTableProps,perVarProps)
            if nargin > 0
                this.perTableProps = perTableProps;
                this.perVarProps = perVarProps;
            end
        end
    end
    
    methods (Hidden)
        function this = subsasgn(this,s,b)
            if ~isstruct(s), s = substruct('.',s); end
            
            switch s(1).type
                case '.'
                    pname = s(1).subs;
                    vnames = fieldnames(this.perVarProps);
                    tnames = fieldnames(this.perTableProps);
                    switch pname
                        case vnames
                            this.perVarProps = builtin('subsasgn',this.perVarProps,s,b);
                        case tnames
                            this.perTableProps = builtin('subsasgn',this.perTableProps,s,b);
                        otherwise
                            error(message('MATLAB:table:CustomProperties:InvalidCustomPropName'))
                    end
                case '{}'
                    error(message('MATLAB:table:CustomProperties:CellReferenceNotAllowed'))
                case '()'
                    error(message('MATLAB:table:CustomProperties:ParensReferenceNotAllowed'))
            end
            
        end
        
        function [varargout] = subsref(this,s)
            if ~isstruct(s), s = substruct('.',s); end
            
            switch s(1).type
                case '.'
                    pname = convertCharsToStrings(s(1).subs);
                    vnames = fieldnames(this.perVarProps);
                    tnames = fieldnames(this.perTableProps);
                    switch pname
                        case vnames
                            value = this.perVarProps;
                        case tnames
                            value = this.perTableProps;
                        otherwise
                            error(message('MATLAB:table:CustomProperties:InvalidCustomPropName'))
                    end
                    [varargout{1:nargout}] = subsref(value,s);
                case '{}'
                    error(message('MATLAB:table:CustomProperties:CellReferenceNotAllowed'))
                case '()'
                    error(message('MATLAB:table:CustomProperties:ParensReferenceNotAllowed'))
            end
        end
        
        function n = numArgumentsFromSubscript(this,s,context)
            % This function is for internal use only and will change in a
            % future release.  Do not use this function.
            if isscalar(s) % one level of subscripting
                n = 1; % CustomProperties returns one array for dot. {} and [] error
            elseif context == matlab.mixin.util.IndexingContext.Assignment
                n = 1; % subsasgn only ever accepts one rhs value
            elseif s(end).type == "()"
                % This should never be called with parentheses as the last
                % subscript, but return 1 for that just in case
                n = 1;
            else % multiple subscripting levels
                x = this.subsref(s(1));
                n = numArgumentsFromSubscript(x,s(2:end),context);
            end
        end
        
        % Allows tab completion after dot to suggest variables
        function p = properties(obj)
            % This will be called for properties of an instance, but the built-in will
            % be still be called for the class name.  It will return no properties.
            % get 1 or 0 newlines based on format loose/compact
            import matlab.internal.display.lineSpacingCharacter 
            [vnames, tnames] = getNames(obj);
            pp = [tnames; vnames];
            if nargout == 0
                fprintf([lineSpacingCharacter '%s\n' lineSpacingCharacter], getString(message('MATLAB:ClassUstring:PROPERTIES_FUNCTION_LABEL',class(obj))));
                fprintf('    %s\n',pp{:});
                fprintf(lineSpacingCharacter);
            else
                p = pp;
            end
        end
        function f = fieldnames(t), f = properties(t); end
        function f = fields(t),     f = properties(t); end
        
        function tf = isprop(this,prop)
            %ISPROP Returns true if the property exists.
            %   V = ISPROP(H, PROP) Returns true if PROP is a property of H.
            %   V is a logical array of the same size as H.  Each true element of V
            %   corresponds to an element of H that has the property PROP.
            if matlab.internal.datatypes.isScalarText(prop,false)
                tf = isfield(this.perTableProps,prop) || isfield(this.perVarProps,prop);
            else
                tf = false;
            end
        end
    end
    
    methods (Access = 'protected')
        function groups = getPropertyGroups(obj)
            % Overloading default display with CustomDisplay
            s = matlab.internal.datatypes.mergeScalarStructs(obj.perTableProps,obj.perVarProps);
            groups = matlab.mixin.util.PropertyGroup(s);
        end
        
        function header = getHeader(obj)
            % Overloading default display with CustomDisplay
            s = matlab.internal.datatypes.mergeScalarStructs(obj.perTableProps, obj.perVarProps);
            
            headerStr = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
            headerStr = getString(message('MATLAB:ObjectText:DISPLAY_AND_DETAILS_SCALAR_WITH_PROPS',headerStr));
            header = sprintf('%s\n',headerStr);
        end
    end
    
    methods (Access = {?matlab.tabular.TabularProperties, ?tabular, ...
            ?matlab.internal.datatools.sidepanelwidgets.propediting.VariableMetaDataObj, ...
            ?matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj})
        function [vnames, tnames] = getNames(obj)
            vnames = fieldnames(obj.perVarProps);
            tnames = fieldnames(obj.perTableProps);
        end
    end
    
    %%%% PERSISTENCE BLOCK ensures correct save/load across releases Properties %%
    %%%% Properties and methods in this block maintain the exact class schema %%%%
    %%%% required for CustomProperties to persist through MATLAB releases %%%%%%%%
    properties(Constant, Access='protected')
        % Version of this CustomProperties serialization and deserialization
        % format. This is used for managing forward compatibility. Value is
        % saved in 'versionSavedFrom' when an instance is serialized.
        %
        %   1.0 : 18b. first shipping version
        version = 1.0;
    end
    
    methods(Hidden)
        function cp_serialized = saveobj(obj)
            % SAVEOBJ must maintain that all ingredients required to recreate
            % a valid CUSTOMPROPERTIES in this and previous version of MATLAB are
            % present and valid in CP_SERIALIZED; any new ingredients needed
            % by future version are created in that version's LOADOBJ.
            % New ingredients MUST ONLY be saved as new fields in CP_SERIALIZED,
            % rather than as modifications to existing fields
            cp_serialized.tabularProps = obj.perTableProps; % Scalar struct. Default empty. Custom meta-data for a tabular instance.
            cp_serialized.varProps     = obj.perVarProps;   % Scalar struct. Default empty. Custom per-variable meta-data for a tabular instance.
            
            % Set minimum version this schema is backward compatible to
            cp_serialized = obj.setCompatibleVersionLimit(cp_serialized, 1.0);
        end
    end
    
    methods(Hidden, Static)
        function obj = loadobj(cp_serialized)
            % LOADOBJ has knowledge of the ingredients needed to create a
            % CUSTOMPROPERTIES in the current version of MATLAB from a
            % serialized struct saved in either the current or previous
            % version; a serialized struct created in a future version of
            % MATLAB will have any new ingredients unknown to the current
            % version as fields of the struct, but those are never accessed
            
            % Always default construct an empty instance, and recreate a
            % proper CustomProperties in the current schema using attributes
            % loaded from the serialized struct
            obj = matlab.tabular.CustomProperties();
            
            % Return an empty instance if current version is below the
            % minimum compatible version of the serialized object
            if obj.isIncompatible(cp_serialized, 'MATLAB:table:CustomProperties:IncompatibleLoad')
                return;
            end
            
            % Restore serialized properties
            obj.perTableProps = cp_serialized.tabularProps;
            obj.perVarProps   = cp_serialized.varProps;
        end
    end
end
