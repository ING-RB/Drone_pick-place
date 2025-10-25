classdef (Sealed) vartype < matlab.internal.tabular.private.subscripter
%

%   Copyright 2016-2024 The MathWorks, Inc.

    
    properties(Transient, Access='protected')
        type
    end
    
    methods
        function obj = vartype(type,~)
            %

            % Add an extra unused input to allow the error handling to catch the common
            % mistake of passing in a time/table as an extra first input. Otherwise, the
            % front-end throws "Too many input arguments".)
            import matlab.internal.datatypes.isScalarText
                                  
            if nargin == 0
                % No input constructor, type will be empty and vartype will not match anything
                obj.type = '';
                return
            end
            
            if istabular(type) % common error: vartype(tt,type)
                error(message('MATLAB:vartype:TabularInput'));
            elseif nargin > 1
                error(message('MATLAB:TooManyInputs')); % as if the extra dummy input wasn't there
            elseif ~isScalarText(type,true) || any(ismissing(type)) % allow vartype(''), the default, but not missing
                % Invalid type provided, must be a (pseudo-)type name
                error(message('MATLAB:vartype:InvalidType'));
            end
            
            obj.type = char(type);
        end

        function t = keyMatch(~,~) %#ok<STOUT> 
            %

            %KEYMATCH True if two keys are the same.
            %   keyMatch(d1,d2) returns logical 1 (true) if arrays d1 and d2 are
            %   both the same class and equal. Returns 0 (false) otherwise.
            %
            %   See also keyHash, dictionary, isequal, eq.
            error(message("MATLAB:datatypes:InvalidTypeKeyMatch","vartype"));
        end

        function h = keyHash(~) %#ok<STOUT> 
            %

            %KEYHASH Generates a hash code
            %   h = keyHash(d) returns a uint64 scalar that represents the input array. Note that
            %   hash values are not guaranteed to be consistent across different MATLAB sessions.
            %
            % See also keyMatch, dictionary.
            error(message("MATLAB:datatypes:InvalidTypeKeyHash","vartype"));
        end
    end
    methods(Access={?withtol, ?timerange, ?vartype, ?matlab.io.RowFilter, ?matlab.internal.tabular.private.tabularDimension, ?tabular})
        % The getSubscripts method is called by table subscripting to find the indices
        % of the times (if any) along that dimension that fall between the specified
        % first and last time.
        function subs = getSubscripts(obj,t,operatingDim)
            if ~matches(operatingDim,'varDim')
                % Only variable subscripting is supported. VARTYPE is used on
                % non-variable dimension if operatingDim is not varDim.
                error(message('MATLAB:vartype:InvalidSubscripter'));
            end
            % Return the indices of variables that match the type
            tData = t.data;
            dataWidth = t.varDim.length;
            subs = false(1,dataWidth);
            if obj.type == "cellstr"
                for i = 1:dataWidth
                    subs(i) = iscellstr(tData{i});
                end
            else
                for i = 1:dataWidth
                    subs(i) = isa(tData{i}, obj.type);
                end
            end
        end
    end
    methods(Hidden = true)
        function disp(obj)      
            % Take care of formatSpacing
            import matlab.internal.display.lineSpacingCharacter;
            import matlab.internal.datatypes.addClassHyperlink;
            tab = sprintf('\t');
                       
            classNameLine = getString(message('MATLAB:vartype:UIStringDispHeader'));
            disp([tab addClassHyperlink(classNameLine,mfilename('class')) lineSpacingCharacter]); % no hyperlink added if hotlinks off
            disp([tab tab getString(message('MATLAB:vartype:UIStringDispType',char(obj.type))) lineSpacingCharacter]);
            if matlab.internal.display.isHot
                disp([tab getString(message('MATLAB:vartype:UIStringDispFooter')) lineSpacingCharacter]);
            end
        end
    end
    
    %%%% PERSISTENCE BLOCK ensures correct save/load across releases %%%%%%
    %%%% Properties and methods in this block maintain the exact class %%%%
    %%%% schema required for VARTYPE to persist through MATLAB releases %%%
    properties(Constant, Access='protected')
        % current running version. This is used only for managing forward
        % compatibility. Value is not saved when an instance is serialized
        %
        %   1.0 : 16b. first shipping version
        %   1.1 : 18a. added serialized field 'incompatibilityMsg' to support
        %              customizable 'kill-switch' warning message. The field
        %              is only consumed in loadobj() and does not translate
        %              into any table property

        version = 1.1;
    end
    
    methods(Hidden)
        function s = saveobj(obj)
            s = struct;
            s = obj.setCompatibleVersionLimit(s, 1.0); % limit minimum version compatible with a serialized instance            
            
            s.type = obj.type; % a single character vector. Contains an arbitrary type name
        end
    end
    
    methods(Hidden, Static)
        function obj = loadobj(s)
            % Always default construct an empty instance, and recreate a
            % proper vartype in the current schema using attributes
            % loaded from the serialized struct                
            obj = vartype();
            
            % Pre-18a (i.e. v1.0) saveobj did not save the versionSavedFrom
            % field. A missing field would indicate it is serialized in
            % version 1.0 format. Append the field if it is not present.
            if ~isfield(s,'versionSavedFrom')
                s.versionSavedFrom = 1.0;
            end            
            
            % Return the empty instance if current version is below the
            % minimum compatible version of the serialized object
            if obj.isIncompatible(s,'MATLAB:vartype:IncompatibleLoad')
                return;
            end
            
            % Restore serialized data
            % ASSUMPTION: 1. type and semantics of the serialized struct
            %                fields are consistent as stated in saveobj above.
            %             2. as a result of #1, the values stored in the
            %                serialized struct fields are valid in this
            %                version of vartype, and can be assigned into
            %                the reconstructed object without any check
            obj.type = s.type;
        end
    end
end
