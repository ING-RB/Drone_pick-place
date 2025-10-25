classdef RMWEnvironment < matlab.mixin.SetGet
    %RMWEnvironment Manage RMW_IMPLEMENTATION environment
  
    %  Copyright 2022 The MathWorks, Inc.
    
    properties (GetAccess = 'public', SetAccess = 'public', Dependent)
        RMWImplementation(1,:) char
    end

    properties (Access = 'private')
        RMWImplementationInternal
    end

    properties (Constant, Access = ?ros.internal.mixin.ROSInternalAccess)
        PREFGROUP = 'ROSToolbox'
        PREFNAME = 'RMW_IMPLEMENTATION'
    end

    methods
        function obj = RMWEnvironment
        end

        function rmwImpl = get.RMWImplementation(obj)
            if ispref(obj.PREFGROUP,obj.PREFNAME)
                rmwImpl = getpref(obj.PREFGROUP,obj.PREFNAME);
            else
                rmwImpl = '';
            end
        end

        function set.RMWImplementation(obj, rmwImpl)
            if isempty(rmwImpl)
                obj.RMWImplementationInternal = '';
            else
                validateattributes(rmwImpl, {'char', 'string'},{'scalartext'});
                rmwImpl = strtrim(convertStringsToChars(rmwImpl));
                obj.RMWImplementationInternal = rmwImpl;
            end
            prefPresent = obj.checkAndGetPref();
            if ~prefPresent %let us initialize right away
                saveRMWEnvironment(obj);
            end
        end
    end

    methods (Access=private, Hidden)
        % Get the pref and if the pref is present, get the map from the
        % preference. Also verify that the version is same as expected
        function validPref = checkAndGetPref(h)
            validPref = false;
            prefPresent = ispref(h.PREFGROUP, h.PREFNAME);
            prefStruct = getpref(h.PREFGROUP);
            if prefPresent
                if strcmp(h.RMWImplementationInternal, prefStruct.RMW_IMPLEMENTATION)
                    validPref = true;
                end
            end
        end
    end
        
    methods(Hidden)
        function saveRMWEnvironment(obj)
            setpref(obj.PREFGROUP,obj.PREFNAME,obj.RMWImplementationInternal);
        end

        function clearRMWEnvironment(obj)
            prefs = {obj.PREFNAME};
            prefExist = ispref(obj.PREFGROUP,prefs);
            if any(prefExist)
                rmpref(obj.PREFGROUP,prefs(prefExist));
            end
        end
    end

end
