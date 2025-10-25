classdef DDSEnvironment < matlab.mixin.SetGet
    %DDSEnvironment Manage DDS environment
  
    %  Copyright 2022 The MathWorks, Inc.
    properties
        DDSHome(1,:) char
    end

    properties (Dependent, SetAccess = private)
        DDSRoot
        DDSArchName
    end

    properties (Constant, Access = ?ros.internal.mixin.ROSInternalAccess)
        PrefGroup = 'ROSToolbox'
        RTIHomePref = 'NDDSHOME'
        RTIArchPref = 'CONNEXTDDS_ARCH'
    end

    methods
        function obj = DDSEnvironment
            %DDSEnvironment Construct an instance of this class 
        end

        function checkAndCreatePref(obj, arch)
            % If not set, get defaults for DDS root
            ddsRoot = getDefaultDDSRoot(obj); % Does not throw exception
            prefs = {obj.RTIHomePref, obj.RTIArchPref};
            prefExist = ispref(obj.PrefGroup,prefs);
            if ~any(prefExist)
                saveDDSEnvironment(obj,ddsRoot,arch);
            end
        end

        function ddsArchId = get.DDSArchName(obj)
            if ispref(obj.PrefGroup,obj.RTIArchPref)
                ddsArchId = getpref(obj.PrefGroup,obj.RTIArchPref);
            else
                ddsArchId = '';
            end
        end

        function ddsRoot = get.DDSRoot(obj)
            if ispref(obj.PrefGroup,obj.RTIHomePref)
                ddsRoot = getpref(obj.PrefGroup,obj.RTIHomePref);
            else
                ddsRoot = '';
            end
        end

        function set.DDSHome(obj,ddsRoot)
            % Empty value is allowed
            ddsRoot = strtrim(convertStringsToChars(ddsRoot));
            obj.DDSHome = ddsRoot;
        end
    end

    methods (Hidden)
        function ddsRoot = getDefaultDDSRoot(obj)
            % Return default dds root

            % Rules: 
            % 1. Use the obj.DDSHome value set by the caller
            % 2. Use environment variable 'NDDSHOME'
            % 3. Use value set in preferences
            if ~isempty(obj.DDSHome)
                ddsRoot = obj.DDSHome;
                return
            end

            % Rule #2: fetch value from NDDSHOME environment variable
            if ~isempty(getenv('NDDSHOME'))
                ddsRoot = getenv('NDDSHOME');
                return
            end

            % Rule #3: Read saved value in preferences
            propName = 'DDSRoot';
            if ~isempty(obj.(propName))
                ddsRoot = obj.(propName);
                return
            end
            ddsRoot = '';
        end

        function saveDDSEnvironment(obj, ddsRoot,arch)
            setpref(obj.PrefGroup,obj.RTIHomePref,ddsRoot);
            setpref(obj.PrefGroup,obj.RTIArchPref,arch);
        end

        function clearDDSEnvironment(obj)
            prefs = {obj.RTIHomePref, obj.RTIArchPref};
            prefExist = ispref(obj.PrefGroup,prefs);
            if any(prefExist)
                rmpref(obj.PrefGroup,prefs(prefExist));
            end
        end
    end
end

