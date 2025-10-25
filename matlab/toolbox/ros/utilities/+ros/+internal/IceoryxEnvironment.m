classdef IceoryxEnvironment < matlab.mixin.SetGet
    %IceoryxEnvironment Manage Iceoryx environment
  
    %  Copyright 2022 The MathWorks, Inc.
    properties
        IceoryxHome(1,:) char
    end

    properties (Dependent, SetAccess = private)
        IceoryxRoot
    end

    properties (Constant, Access = ?ros.internal.mixin.ROSInternalAccess)
        PrefGroup = 'ROSToolbox'
        IceoryxHomePref = 'ICEORYX_HOME'
    end

    methods
        function obj = IceoryxEnvironment
            %IceoryxEnvironment Construct an instance of this class 
        end

        function checkAndCreatePref(obj)
            % If not set, get defaults for Iceoryx Root
            iceoryxRoot = getDefaultIceoryxRoot(obj); % Does not throw exception
            prefs = {obj.IceoryxHomePref};
            prefExist = ispref(obj.PrefGroup,prefs);
            if ~any(prefExist)
                saveIceoryxEnvironment(obj,iceoryxRoot);
            end
        end

        function iceoryxRoot = get.IceoryxRoot(obj)
            if ispref(obj.PrefGroup,obj.IceoryxHomePref)
                iceoryxRoot = getpref(obj.PrefGroup,obj.IceoryxHomePref);
            else
                iceoryxRoot = '';
            end
        end

        function set.IceoryxHome(obj,iceoryxRoot)
            % Empty value is allowed
            iceoryxRoot = strtrim(convertStringsToChars(iceoryxRoot));
            obj.IceoryxHome = iceoryxRoot;
        end
    end

    methods (Hidden)
        function iceoryxRoot = getDefaultIceoryxRoot(obj)
            % Return default iceoryx root

            % Rules: 
            % 1. Use the obj.IceoryxHome value set by the caller
            % 3. Use value set in preferences
            if ~isempty(obj.IceoryxHome)
                iceoryxRoot = obj.IceoryxHome;
                return
            end

            % Rule #3: Read saved value in preferences
            propName = 'IceoryxRoot';
            if ~isempty(obj.(propName))
                iceoryxRoot = obj.(propName);
                return
            end
            iceoryxRoot = '';
        end

        function saveIceoryxEnvironment(obj, iceoryxRoot)
            setpref(obj.PrefGroup,obj.IceoryxHomePref,iceoryxRoot);
        end

        function clearIceoryxEnvironment(obj)
            prefs = {obj.IceoryxHomePref};
            prefExist = ispref(obj.PrefGroup,prefs);
            if any(prefExist)
                rmpref(obj.PrefGroup,prefs(prefExist));
            end
        end
    end
end
