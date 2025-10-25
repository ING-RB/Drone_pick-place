classdef DataStoreHelper < handle
    %DATASTOREHELPER - Use this class to access data in DataStore
    % call "matlab.hwmgr.internal.DataStoreHelper.getDataStore.<method>"
    % Example
    % "matlab.hwmgr.internal.DataStoreHelper.getDataStore.getAllKeywords"
    
    % Copyright 2021 The MathWorks, Inc.

    properties (Hidden, Constant)
        DataStore = matlab.hwmgr.internal.DataStore()
    end

    methods
        function obj = DataStoreHelper()
        end
    end

    methods (Static)
        function dataStore = getDataStore()
            mlock;
            dataStore = matlab.hwmgr.internal.DataStoreHelper.DataStore;
        end

        function unlockDataStore()
            munlock('matlab.hwmgr.internal.DataStoreHelper.getDataStore');
        end
    end
end