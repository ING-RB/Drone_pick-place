classdef MiddlewareEnvironment < matlab.mixin.SetGet
    %MiddlewareEnvironment Manage Custom Middleware Environment
  
    %  Copyright 2022 The MathWorks, Inc.
    properties
        MiddlewareHome(1,:) char
    end

    properties (Dependent, SetAccess = private)
        MiddlewareRoot
    end

    properties (Constant, Access = ?ros.internal.mixin.ROSInternalAccess)
        PrefGroup = 'ROSToolbox'
        MiddlewareHomePref = 'MiddlewareHome'
    end

    properties (Hidden, SetAccess=protected)
        MiddlewareMap %Middleware map that is saved and retrieved
    end

    methods (Static)
        function ret = getInstance(varargin)
            persistent instance
            if isempty(instance)
                instance = ros.internal.MiddlewareEnvironment();
            end
            ret = instance;
        end
    end

    methods (Access = private)
        function obj = MiddlewareEnvironment
            obj.MiddlewareMap = containers.Map(); % an empty map
            obj.refresh;
        end
    end        

    %% Public
    methods
        function refresh(obj)
            middlewareInstallPrefPresent = obj.checkAndGetMiddlewarePref();
            if ~middlewareInstallPrefPresent
                obj.saveMiddlewareInstallationEnvironment();
            end
        end

        function middlewareRootMap = get.MiddlewareRoot(obj)
            if ispref(obj.PrefGroup,obj.MiddlewareHomePref)
                middlewareRootMap = getpref(obj.PrefGroup,obj.MiddlewareHomePref);
            else
                middlewareRootMap = '';
            end
        end

        function set.MiddlewareHome(obj,middlewareRoot)
            % Empty value is allowed
            middlewareRoot = strtrim(convertStringsToChars(middlewareRoot));
            obj.MiddlewareHome = middlewareRoot;
        end

        function updateMiddlewareInstallationEntry(obj, key, value)
            % Update the Middleware installation and save in the preferences
            obj.MiddlewareMap(key) = value;
            obj.saveMiddlewareInstallationEnvironment();
        end

        function removeMiddlewareInstallationEntry(obj,key)
            if obj.MiddlewareMap.isKey(key)
                obj.MiddlewareMap.remove(key);
                obj.saveMiddlewareInstallationEnvironment();
            end
        end


        function clearMiddlewareInstallationEnvironment(obj)
            prefs = {obj.MiddlewareHomePref};
            prefExist = ispref(obj.PrefGroup,prefs);
            if any(prefExist)
                rmpref(obj.PrefGroup,prefs(prefExist));
            end
        end
    end

     methods (Access=private, Hidden)
         function validPref = checkAndGetMiddlewarePref(obj)
             validPref = false;
             prefs = {obj.MiddlewareHomePref};
             prefExist = ispref(obj.PrefGroup,prefs);
             prefStruct = getpref(obj.PrefGroup);
             if prefExist
                 validPref = isa(prefStruct.MiddlewareHome, 'containers.Map');
                 if validPref
                     obj.MiddlewareMap = prefStruct.MiddlewareHome;
                 end
             end
         end

        function saveMiddlewareInstallationEnvironment(obj)
            setpref(obj.PrefGroup, obj.MiddlewareHomePref, obj.MiddlewareMap);
        end
    end
end
