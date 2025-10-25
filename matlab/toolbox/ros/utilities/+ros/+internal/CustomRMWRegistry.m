classdef CustomRMWRegistry < handle
    % This class is for internal use only. It may be removed in the future.

    % CustomRMWRegistry is a class used to save and retrieve information
    % about the rmw implementation package.

    % Copyright 2022 The MathWorks, Inc.

    properties (Constant, Hidden)
        PREFGROUP = 'ROSToolbox'
        PREFNAME  = 'CustomRMWMap'
    end

    properties (Hidden, SetAccess=protected)
        RMWMap %RMW map that is saved and retrieved
    end

    %% Helpers
    methods (Static)
        %Helper to remove stale items only once
        %Users can call removeStale at any time to cleanup the registry
        function checkOnce(inst, reset)
            persistent rmwChecked;
            if isempty(rmwChecked) || reset
                inst.removeStale();
                rmwChecked = true;
            end
        end
    end

    methods (Access=private, Hidden)
        % Get the pref and if the pref is present, get the map from the
        % preference.
        function validPref = checkAndGetPref(h)
            validPref = false;
            prefPresent = ispref(h.PREFGROUP, h.PREFNAME);
            prefStruct = getpref(h.PREFGROUP);
            if prefPresent
                validPref = isa(prefStruct.CustomRMWMap, 'containers.Map');
                if validPref
                    h.RMWMap = prefStruct.CustomRMWMap;
                end
            end
        end

        % Save all the preference items
        function savePref(h)
            setpref(h.PREFGROUP, h.PREFNAME, h.RMWMap);
        end

        %Helper to create the entry to be used in map
        function ent = createEntry(~, ~, installDir,srcPath, dllPath, middlewarePath)
            ent = struct('installDir', installDir, ...
                'srcPath', srcPath, ...
                'dllPath', dllPath, ...
                'middlewarePath', middlewarePath);
        end

        %removeStale removes stale items
        %called on refresh(reset)
        function removeStale(h)
            keys = h.RMWMap.keys;
            for i = 1:numel(keys)
                ent = h.RMWMap(keys{i});
                if ~isfolder(ent.installDir) || isempty(dir(ent.dllPath))
                    h.RMWMap.remove(keys{i});
                    h.savePref();
                end
            end
        end
    end

    methods (Static)
        function ret = getInstance(varargin)
            persistent rmwRegInstance
            persistent previousROSVarargin
            if isempty(rmwRegInstance) || ~isequal(varargin,previousROSVarargin)
                rmwRegInstance = ros.internal.CustomRMWRegistry(varargin{:});
                previousROSVarargin = varargin;
            end
            ret = rmwRegInstance;
        end
    end

    methods (Access = private)
        % CustomRMWRegistry
        % CustomRMWRegistry(true) to force a reset (i.e. remove stale)
        function h = CustomRMWRegistry(reset)
            if nargin < 2
                reset = false;
            end
            h.RMWMap = containers.Map(); % an empty map
            h.refresh(reset);
        end
    end

    %% Public
    methods
        % refresh gets the registry again from preference
        % refresh(reset) gets the registry and removes stale items
        function refresh(h, reset)
            prefPresent = h.checkAndGetPref();
            if ~prefPresent %let us initialize right away
                h.savePref();
            else
                ros.internal.CustomRMWRegistry.checkOnce(h, reset);
            end
        end

        % getRMWInfo(name) gets the entry in the map for a given RMW
        function customRMWInfo = getRMWInfo(h, name)
            if ~isempty(h.RMWMap) && h.RMWMap.isKey(name)
                customRMWInfo = h.RMWMap(name);
            else
                customRMWInfo = [];
            end
        end

        %getRMWList gets the list of messages registered
        function rmwList = getRMWList(h)
            rmwList = {};
            if ~isempty(h.RMWMap)
                rmwList = h.RMWMap.keys();
            end
        end

        %getBinDirList gets all folders containing custom message DLLs
        function dirList = getBinDirList(h)
            rmwList = getRMWList(h);
            rmwInfoList = cellfun(@(rmw) getRMWInfo(h, rmw), rmwList);
            dirList = arrayfun(@(rmwInfo) fileparts(rmwInfo.dllPath), ...
                rmwInfoList, 'UniformOutput', false);
            dirList = unique(dirList);
        end

        %updateRMWInfo(rmwInfo) given a rmwInfo (returned from
        %getRMWInfo), if the rmw is registered as custom, will be
        %overwritten with registry entry
        function rmwInfo = updateRMWInfo(h, rmwInfo)
            name = rmwInfo.pkgName;
            if ~isempty(h.RMWMap) && h.RMWMap.isKey(name)
                ent = h.RMWMap(name);
                rmwInfo.custom = true;
                rmwInfo.path = ent.dllPath;
                rmwInfo.srcPath = ent.srcPath;
                rmwInfo.installDir = ent.installDir;
                rmwInfo.middlewarePath = middlewarePath;
            end
        end

        %updateRMWEntry(name, installDir, dllPath) adds an
        %entry if one does not exist or updates the existing entry
        function updateRMWEntry(h, name, installDir, srcPath, dllPath, middlewarePath)
            info = h.createEntry(name, installDir,srcPath, dllPath, middlewarePath);
            h.RMWMap(name) = info;
            h.savePref();
        end

        %removeRMWEntry(name) removes a given rmw entry
        function removeRMWEntry(h,name)
            if h.RMWMap.isKey(name)
                h.RMWMap.remove(name);
                h.savePref();
            end
        end
    end
end

% LocalWords:  DLL DLLs custommessages
