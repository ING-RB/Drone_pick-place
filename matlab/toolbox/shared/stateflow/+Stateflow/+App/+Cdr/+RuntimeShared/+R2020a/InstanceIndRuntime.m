classdef InstanceIndRuntime < handle
%

%   Copyright 2018-2020 The MathWorks, Inc.

    properties
        commonUtils;
        externalSimCurrentTime = -1
        testingForMATLABInstall = false
        runtimeExceptionStacks = []
        subscribedToDebugEvents = false;
        recursionLimit = 200;

    end
    methods(Access=private)
        function obj = InstanceIndRuntime
        end
    end
    methods(Static)
        function retval = instance
            persistent obj
            if isempty(obj)
                obj = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime;
                obj.commonUtils = Stateflow.internal.getCommonUtils();
                obj.externalSimCurrentTime = -1;
                obj.testingForMATLABInstall = false;
                obj.runtimeExceptionStacks = [];
            end
            retval = obj;
        end

        function versionCheck(chartName, MATLABVersion, SfVersion)
            assert(isempty(coder.target()), 'versionCheck should be called for MATLAB execution only');
            coder.ignoreCatch();
            try
                MVersion = "R" + MATLABVersion;
                versionMismatch = Stateflow.App.Utils.checkModelWithCurrentVersion(MVersion, SfVersion);
                if versionMismatch == -1 % model is saved in later major version
                    errId = 'MATLAB:sfx:VersionMismatch';
                    msg = getString(message(errId,Stateflow.App.Utils.getChartHyperlink(chartName)));
                    error(errId, msg);
                end
            catch ME
                ME.throwAsCaller();
            end
        end

        function verifyForEmptyData(sfxObject, chartName)
            emptyData = {};
            emptyDataNames ='';
            for counterVar = 1 : length(sfxObject.sfInternalObj.chartAllData)
                if isempty(sfxObject.(sfxObject.sfInternalObj.chartAllData{counterVar}))
                    emptyData{end+1} = sfxObject.sfInternalObj.chartAllData{counterVar}; %#ok<AGROW>
                    ssId = sfxObject.sfInternalObj.chartAllDataSSID{counterVar};
                    dataName = sfxObject.sfInternalObj.chartAllData{counterVar};
                    link = ['<a href="matlab:Stateflow.App.Cdr.Utils.openAndHighlightDataInSymbolsWindow(''' chartName ''', ''' num2str(ssId) ''')">'''  dataName '''</a>'];
                    emptyDataNames = [emptyDataNames link ', ']; %#ok<AGROW>
                end
            end

            % populate warning message
            warnId = 'MATLAB:sfx:EmptyDataAfterInitialization';
            msg = getString(message(warnId, Stateflow.App.Utils.getChartHyperlink(chartName), emptyDataNames(1:end-2)));

            % throw warning
            if ~isempty(emptyData) && sfxObject.sfInternalObj.warningOnUninitializedData && sfxObject.sfInternalObj.executeInitStep
                Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.throwWarning(warnId, msg, chartName);
            end
        end


        function verifyStepArguments(sfxObject, chartName, varargin )
            try
                for counterVar = 1 :2: length(varargin)
                    if ~ischar(varargin{counterVar})
                        errId = 'MATLAB:sfx:InvalidStepOrEventArgument';
                        msg = getString(message(errId,num2str(counterVar),chartName));
                        msg = [msg newline eval(['help(''' chartName ''')'])]; %#ok<AGROW>
                        Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.throwError(errId, msg,chartName, 'OnlyCMD');
                    elseif isempty(find(strcmp(sfxObject.sfInternalObj.chartAllData, varargin{counterVar}), 1))
                        errId = 'MATLAB:sfx:StepOrEventArgumentErrorDataNameIncorrect';
                        msg = getString(message(errId,num2str(counterVar),chartName, varargin{counterVar}));
                        msg = [msg newline eval(['help(''' chartName ''')'])]; %#ok<AGROW>
                        Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.throwError(errId, msg,chartName, 'OnlyCMD');
                    elseif counterVar == length(varargin)
                        errId = 'MATLAB:sfx:StepOrEventArgumentErrorNoValue';
                        msg = getString(message(errId,varargin{counterVar},chartName));
                        msg = [msg newline eval(['help(''' chartName ''')'])]; %#ok<AGROW>
                        Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.throwError(errId, msg,chartName, 'OnlyCMD');
                    else
                        sfxObject.set(varargin{counterVar}, varargin{counterVar+1});
                    end
                end
            catch ME
                ME.throwAsCaller();
            end

        end

        function throwInvalidConstructorArgumentError(chartName, sfxObject, argumentNumber)
            instanceIndRuntimeH = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
            errId = 'MATLAB:sfx:InvalidConstructorArgument';
            errMsg = getString(message(errId, num2str(argumentNumber), chartName));
            errMsg = [errMsg newline eval(['help(''' chartName ''')'])];
            instanceIndRuntimeH.throwErrorAsCallerWithDummyRuntime(errId, errMsg, sfxObject, chartName);
        end
        function parseConfigArguments(sfxObject, numberOutput, chartName, mangledVars, varargin )
            try
                instanceIndRuntimeH = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
                if numberOutput ~= 1
                    errId = 'MATLAB:sfx:ConstructorOutputMismatch';
                    msg = getString(message(errId,chartName, num2str(numberOutput)));
                    msg = [msg newline eval(['help(''' chartName ''')'])];
                    instanceIndRuntimeH.throwErrorAsCallerWithDummyRuntime(errId, msg, sfxObject, chartName);
                end
                if mod(length(varargin), 2) ~= 0
                    % constructor accepts name value pair, so number of
                    % arguments must be even
                    errId = 'MATLAB:sfx:InvalidConstructorArgumentNameWithNoValue';
                    msg = getString(message(errId,num2str(length(varargin)),chartName));
                    msg = [msg newline eval(['help(''' chartName ''')'])];
                    instanceIndRuntimeH.throwErrorAsCallerWithDummyRuntime(errId, msg, sfxObject, chartName);
                end
                for counterVar = 1:2:length(varargin)
                    if ~ischar(varargin{counterVar})
                        errId = 'MATLAB:sfx:InvalidConstructorArgument';
                        msg = getString(message(errId,num2str(counterVar),chartName));
                        msg = [msg newline eval(['help(''' chartName ''')'])]; %#ok<AGROW>
                        instanceIndRuntimeH.throwErrorAsCallerWithDummyRuntime(errId, msg, sfxObject, chartName);
                    end

                    if ~startsWith(varargin{counterVar}, '-')
                        % This might be a chart data name.
                        % This case is handled in parseDataArguments
                        indexVar = find(strcmp(sfxObject.chartAllData__, varargin{counterVar}), 1);
                        if ~isempty(indexVar)
                            sfxObject.IsDataInitialized__(indexVar) = true;
                        end
                        continue;
                    end

                    switch  varargin{counterVar}
                      case '-enableAnimation'
                        if ~islogical(varargin{counterVar + 1})
                            instanceIndRuntimeH.throwInvalidConstructorArgumentError(chartName, sfxObject, counterVar);
                        end
                        sfxObject.sfInternalObj.enableAnimation = varargin{counterVar + 1};
                      case '-eventQueueSize'
                        if ~isnumeric(varargin{counterVar + 1}) || ...
                                ~isscalar(varargin{counterVar + 1}) ...
                                || round(varargin{counterVar + 1},0) ~= varargin{counterVar + 1}
                            % Previous check (i.e. round...) differentiates between a double & an integer.
                            % e.g. foo('-eventQueueSize', 3), here value 3 is considered as double by MATLAB.
                            % Hence we cannot use isa(3, 'integer')
                            instanceIndRuntimeH.throwInvalidConstructorArgumentError(chartName, sfxObject, counterVar);
                        end
                        sfxObject.(mangledVars.evtQueueCapacityVar) = varargin{counterVar + 1};
                        sfxObject.(mangledVars.evtQueueVar) = repmat({''},1,varargin{counterVar + 1});
                        sfxObject.(mangledVars.evtQueueArgsVar) = repmat({[]},1,varargin{counterVar + 1});
                      case '-warningOnUninitializedData'
                        if ~islogical(varargin{counterVar + 1})
                            instanceIndRuntimeH.throwInvalidConstructorArgumentError(chartName, sfxObject, counterVar);
                        end
                        sfxObject.sfInternalObj.warningOnUninitializedData = varargin{counterVar + 1};
                      case '-enableDataLogging'
                        sfxObject.sfInternalObj.enableDataLogging = varargin{counterVar + 1};
                      case '-clockSpeedFactor'
                        sfxObject.(mangledVars.clockSpeedFactor) = varargin{counterVar + 1};
                        sfxObject.sfInternalObj.clockSpeedUp = varargin{counterVar + 1};
                      case '-MATLABTimer'
                        sfxObject.sfInternalObj.useMATLABTimerForSFTemporals = varargin{counterVar + 1};
                      case '-externalClock'
                        sfxObject.sfInternalObj.externalClock = varargin{counterVar + 1};
                      case '-executionTimeForTimers'
                        sfxObject.sfInternalObj.executionTimeForTimers = varargin{counterVar + 1};
                      case '-animationDelay'
                        sfxObject.sfInternalObj.animationDelay = varargin{counterVar + 1};
                      case  '-executeInitStep'
                        if ~islogical(varargin{counterVar + 1})
                            instanceIndRuntimeH.throwInvalidConstructorArgumentError(chartName, sfxObject, counterVar);
                        end
                        sfxObject.sfInternalObj.executeInitStep = varargin{counterVar + 1};
                      otherwise
                        instanceIndRuntimeH.throwInvalidConstructorArgumentError(chartName, sfxObject, counterVar);
                    end
                end

            catch ME
                ME.throwAsCaller();
            end

        end


        function parseDataArguments(sfxObject, chartName, varargin )
        % make sure to call parseConfigArguments before calling parseDataArguments
            try
                instanceIndRuntimeH = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;

                for counterVar = 1:2:length(varargin)
                    assert(ischar(varargin{counterVar}) == true, 'must be handled in parseConfigArguments');
                    if startsWith(varargin{counterVar}, '-')
                        % This case is handled in parseConfigArguments
                        continue;
                    end
                    indexVar = find(strcmp(sfxObject.chartAllData__, varargin{counterVar}), 1);
                    if isempty(indexVar)
                        % Provided data name is not valid
                        errId = 'MATLAB:sfx:InvalidConstructorArgument';
                        msg = getString(message(errId,num2str(counterVar),chartName));
                        msg = [msg newline eval(['help(''' chartName ''')'])]; %#ok<AGROW>
                        instanceIndRuntimeH.throwErrorAsCallerWithDummyRuntime(errId, msg, sfxObject, chartName);
                    end
                    dataName = sfxObject.chartAllData__{indexVar};
                    sfxObject.set(dataName, varargin{counterVar + 1});
                end
            catch ME
                ME.throwAsCaller();
            end

        end


        %% temporalOperatorCallbackRouter
        function temporalOperatorCallbackRouter(src, ~)
            try
                chartName = [];
                if isa(src.UserData.sfxInstance, 'handle') && isvalid(src.UserData.sfxInstance)
                    chartName = src.UserData.sfxInstance.sfInternalObj.runtimeVar.chartName;
                    timer_callback(src.UserData.sfxInstance, src.UserData.eventsActivated)
                end
            catch ME
                if ~isempty(chartName)
                    if ispc
                        fprintf(2,Stateflow.App.Utils.escapeBackslash([getReport(ME) newline])); %@coverageexception gets covered on Windows
                    else
                        fprintf(2,[getReport(ME) newline]);
                    end
                    confH = Stateflow.App.Cdr.CdrConfMgr.getInstance();
                    if confH.isUnderTesting
                        confH.debuggerTestingCB.timerME = ME;
                    end
                end
            end
        end

        function objId = getSFXObjId()
            obj = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
            obj.commonUtils.counter = obj.commonUtils.counter + 1;
            objId = obj.commonUtils.counter;
        end
        function clearCurrentInstance()
            runtimeH = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
            runtimeH.commonUtils.currentInstanceId = [];
            runtimeH.commonUtils.currentInstance = [];
        end
        function resetCurrentInstance(sfxObjId)
            runtimeH = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
            if (~isempty(runtimeH.commonUtils.currentInstanceId) && ...
                ~isempty(sfxObjId) &&...
                sfxObjId == runtimeH.commonUtils.currentInstanceId{end})
                runtimeH.commonUtils.currentInstanceId(end) = [];
                runtimeH.commonUtils.currentInstance(end) = [];
            end
        end
        function objId = setCurrentInstance(obj, sfxObjId)
            runtimeH = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
            for i = length(runtimeH.commonUtils.currentInstanceId):-1:1
                if isa(runtimeH.commonUtils.currentInstance{i}, 'handle') && isvalid(runtimeH.commonUtils.currentInstance{i})
                    continue;
                else
                    runtimeH.commonUtils.currentInstance(i) = [];
                    runtimeH.commonUtils.currentInstanceId(i) = [];
                end
            end
            assert (~isempty(obj) &&  isa(obj, 'handle') && isvalid(obj), 'instance is not valid');
            if sfxObjId > 0
                id = sfxObjId;
            else
                id = runtimeH.getSFXObjId();
            end
            objId = id;
            if ~isempty(runtimeH.commonUtils.currentInstanceId) &&...
                    ~isempty(runtimeH.commonUtils.currentInstance) &&...
                    isKey(runtimeH.commonUtils.nestedObjects, runtimeH.commonUtils.currentInstanceId{end}) && ...
                    isa(runtimeH.commonUtils.currentInstance{end},'handle') &&...
                    isvalid(runtimeH.commonUtils.currentInstance{end})
                t = runtimeH.commonUtils.nestedObjects(runtimeH.commonUtils.currentInstanceId{end});
                t{end+1} = obj;
                runtimeH.commonUtils.nestedObjects(runtimeH.commonUtils.currentInstanceId{end}) = t;
            else
                runtimeH.commonUtils.nestedObjects(id) = {};
            end
            runtimeH.commonUtils.currentInstanceId{end+1} = id;
            runtimeH.commonUtils.currentInstance{end+1} = obj;
        end

        function ret = getCounter()
            runtimeH = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
            ret = runtimeH.commonUtils.counter;
        end

        function objs = getNestedObjs(id)
            objs = {};
            runtimeH = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;

            if isKey(runtimeH.commonUtils.nestedObjects, id)
                objs = runtimeH.commonUtils.nestedObjects(id);
            end
        end


        function retVal = getExternalSimCurrentTime()
            instH = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
            retVal = instH.externalSimCurrentTime;
        end

        function setExternalSimCurrentTime(val)
            instH = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
            if isempty(val) || ~isscalar(val) || ~isnumeric(val) || val < 0
                errMsg = 'Simulation time value must be scalar non-negative double.';
                Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.throwError('MATLAB:sfx:InvalidSimTime', errMsg, chartName, 'OnlyCMD');
            elseif val <= instH.externalSimCurrentTime
                errMsg = ['Current simulation time must be larger than previous value of ' num2str(val) '.' newline ...
                          'Use larger time value or reset previous stale value using, ' newline ... '
                          'Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.resetExternalSimCurrentTime()'];
                Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.throwError('MATLAB:sfx:InvalidSimTime', errMsg, chartName, 'OnlyCMD');
            end
            instH.externalSimCurrentTime = val;
        end
        function resetExternalSimCurrentTime()
            instH = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
            instH.externalSimCurrentTime = -1;
        end
        function setTestingForMATLABInstall(val)
            obj = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
            obj.testingForMATLABInstall = val;
        end
        function val = getTestingForMATLABInstall()
            obj = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
            val = obj.testingForMATLABInstall;
        end
        function clearCache()
            obj = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
            obj.commonUtils.counter = 0;
            obj.commonUtils.nestedObjects = containers.Map('KeyType', 'double', 'ValueType', 'any');
            obj.commonUtils.currentInstance = [];
            obj.commonUtils.currentInstanceId = [];
            obj.externalSimCurrentTime = -1;
            obj.testingForMATLABInstall = false;
        end
        function DebugEventCallback(fileName, ~)
            if ~isdeployed
                if ~Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.getTestingForMATLABInstall() && exist(fullfile(matlabroot, 'toolbox', 'stateflow', 'stateflow', '+Stateflow', '+App', 'IsStateflowApp.m'), 'file') %todo
                    disp(getString(message('MATLAB:sfx:LoadStateflowFirstToDebug', fileName)));
                else
                    disp(getString(message('MATLAB:sfx:StateflowNeededForDebug', fileName)));
                end
                matlab.internal.mvm.debug.enqueueDbstepOut;
                matlab.internal.mvm.debug.enqueueDbstep;
            end
        end
        function checkRecursionLimitReached()
            staticRuntimeSharedH = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
            totalInstanceCalls = length(staticRuntimeSharedH.commonUtils.currentInstance);
            if totalInstanceCalls > staticRuntimeSharedH.recursionLimit
                uniqueInstanceCalls = length(unique(arrayfun(@(x) class(x{1}), staticRuntimeSharedH.commonUtils.currentInstance, 'UniformOutput', false)));
                if (~isequal(totalInstanceCalls, uniqueInstanceCalls))
                    staticRuntimeSharedH.clearCache();
                    errId = 'MATLAB:sfx:RecursionLimitReached';
                    Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.throwError(errId, getString(message(errId)), 'dummyChartName', 'OnlyCMD');
                end
            end
        end
        function setRecursionLimit(val)
            staticRuntimeSharedH = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
            staticRuntimeSharedH.recursionLimit = val;
        end
        function throwErrorAsCallerWithDummyRuntime(errId, msg,sfxObject,chartName)
        % this is used by parseConfigArguments to throw errors since by
        % the time of parseConfigArguments, sfxObject runtime is not
        % created.
            try
                sfxObject.sfInternalObj.runtimeVar = Stateflow.App.Cdr.RuntimeShared.R2020a.Animation(chartName);
                error(errId, msg);
            catch ME
                ME.throwAsCaller();
            end

        end
        function throwWarningOnCMDWithoutStack(warnId, msg)
        % Do not use this directly.
        % Use Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.throwWarning
            oldWarningStatus = warning('backtrace');
            warning('off', 'backtrace');
            warning(warnId, msg);
            warning(oldWarningStatus.state, 'backtrace');
        end
        function throwError(errId, errMsg, chartName, errorLocation, suppressStackOnCMD)  %#ok<INUSL>
        % entry-point function to throw errors in Stateflow-in-MATLAB

        % errorLocation: {'ALL','OnlyDV','OnlyCMD'}
        % suppressStackOnCMD: boolean flag. It is a no-op when errorLocation ='OnlyDV'
        % If Stateflow is installed and loaded and chartName is provided
        %   calls Stateflow.App.Studio.handleError which
        %   appropriately chooses DV or CMD to throw warning without showing stack
        % Else
        %   throws warning on command line without showing stack

            if ~exist('errorLocation', 'var')
                errorLocation = 'ALL'; %#ok<NASGU>
            end
            if ~exist('suppressStackOnCMD', 'var')
                suppressStackOnCMD = false;
            end
            if ~Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.getTestingForMATLABInstall() && exist('chartName', 'var')
                if ~isdeployed
                    if exist(fullfile(matlabroot, 'toolbox', 'stateflow', 'stateflow', '+Stateflow', '+App', 'IsStateflowApp.m'), 'file')
                        if eval('Stateflow.App.Cdr.Utils.isStateflowLoaded()')
                            eval('Stateflow.App.Studio.handleError(errId, errMsg, chartName, errorLocation, suppressStackOnCMD)');
                            return;
                        end
                    end
                end
            end

            % Throw errors on CMD
            Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.throwErrorOnCMD(errId, errMsg, chartName, suppressStackOnCMD);
        end
        function throwErrorOnCMD(errId, errMsg, ~, suppressStackOnCMD)
        % Do not use this directly.
        % Use Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.throwError
            if ~suppressStackOnCMD
                error(errId, errMsg);%, errMsg);
            end
            sfxError.message = errMsg;
            if ispc
                sfxError.message = Stateflow.App.Utils.escapeBackslash(sfxError.message);
            end
            sfxError.identifier = errId;
            sfxError.stack.file = '';
            sfxError.stack.name = 'Stateflow (sfx) Model';
            sfxError.stack.line = 1;
            error(sfxError);
        end
        function throwWarning(warnId, msg, chartName) %#ok<INUSD>
        % entry-point function to throw warnings in Stateflow-in-MATLAB

        % If Stateflow is installed and loaded and chartName is provided
        %   calls Stateflow.App.Cdr.Runtime.InstanceIndRuntime.throwWarning which
        %   appropriately chooses DV or CMD to throw warning without showing stack
        % Else
        %   throws warning on command line without showing stack

            if ~Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.getTestingForMATLABInstall() && exist('chartName', 'var')
                if ~isdeployed
                    if exist(fullfile(matlabroot, 'toolbox', 'stateflow', 'stateflow', '+Stateflow', '+App', 'IsStateflowApp.m'), 'file')
                        if eval('Stateflow.App.Cdr.Utils.isStateflowLoaded()')
                            eval('Stateflow.App.Cdr.Runtime.InstanceIndRuntime.throwWarning(chartName, warnId, msg)');
                            return;
                        end
                    end
                end
            end

            % Throw warning on CMD
            Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.throwWarningOnCMDWithoutStack(warnId, msg);

        end

        function [allDataInStruct, timeSeriesData] = getLoggedDataHelper(this, DataNames, loggedDataName)
            allDataInStruct = [];
            timeSeriesData = [];
            if(isempty(coder.target))
                timeSeriesData = {};
                allDataInStruct = {};
                assert(~isempty(this.sfInternalObj.stepCount) && this.sfInternalObj.stepCount > 0, 'wrong step count');
                for countVar = 1:length(DataNames)
                    eval(['allDataInStruct.' DataNames{countVar} ' = this.' loggedDataName '{countVar};']);
                end
                allFieldsFromMAT = fields(allDataInStruct);
                stepData_SFX = allDataInStruct.stepCount;%#ok<NASGU>
                allFieldsFromMAT = setdiff(allFieldsFromMAT, 'stepCount');
                for i = 1:length(allFieldsFromMAT)
                    userData_SFX = eval(['allDataInStruct.' allFieldsFromMAT{i} ';']);%#ok<NASGU>
                    eval(['try ' newline 'timeSeriesData.' allFieldsFromMAT{i} ' = timeseries(cell2mat(userData_SFX), cell2mat(stepData_SFX));' newline 'catch' newline 'try ' newline 'timeSeriesData.' allFieldsFromMAT{i} ' = timeseries([userData_SFX{:}], cell2mat(stepData_SFX));' newline 'catch' newline 'end' newline 'end']);
                end
            end
        end

        function currentTime = getPOSIXTime(sfxObj)
            currentTime = 0;
            if sfxObj.sfInternalObj.externalClock
                currentTime= sfxObj.t__;
                return;
            end
            if coder.target('sfun')
                return;
            end
            [~,inmemOutput_SFX_44] = inmem;
            if exist(fullfile(matlabroot, 'toolbox', 'stateflow', 'stateflow', '+Stateflow', '+App', 'IsStateflowApp.m'), 'file')
                if ~any(strcmp(inmemOutput_SFX_44,'sf'))
                    currentTime= posixtime(datetime('now'));
                elseif Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.getExternalSimCurrentTime() < 0
                    currentTime= posixtime(datetime('now'));
                else
                    currentTime= Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.getExternalSimCurrentTime();
                end
            else
                currentTime= posixtime(datetime('now'));
            end
        end

        function [SfObjectLink, ssid, lineNo, startI, endI, SfObjectName] = getSFXObjectLink(filePath, fcnName, lineNumber)
            ssid = [];
            lineNo = [];
            startI = [];
            endI = [];
            SfObjectLink = [];
            SfObjectName='SFX_Internal_Fcn';

            confH = Stateflow.App.Cdr.CdrConfMgr.getInstance(); %%@todo to move to shared
            if confH.generatedCodeDebugging
                sfxExtension = '_sfxdebug_.m';
                filePath = [filePath(1:end-length(sfxExtension)) '.sfx'];
            end
            [~, modelName, ~] = fileparts(filePath);
            if confH.generatedCodeDebugging
                sfxExtension = '_sfxdebug_';
                modelNameForFcnPrefix = [modelName sfxExtension];
            else
                modelNameForFcnPrefix = modelName;
            end

            fullFilePath = which(filePath);
            sfxFileReader = Simulink.loadsave.SLXPackageReader(fullFilePath);
            debugInfo = sfxFileReader.readPartToVariable('/code/debugInfoForSFXRuntime');
            if ~debugInfo.UserLineToSSID.isKey(lineNumber)
                return;
            end
            ssid = debugInfo.UserLineToSSID(lineNumber);
            objType = debugInfo.UserLineToMethodTypeId(lineNumber);
            fcnType = debugInfo.UserLineToSFFunctionType(lineNumber);
            lineNo = debugInfo.UserLineToMLFcnLineNo(lineNumber);
            startI = debugInfo.UserLineToStartI(lineNumber);
            endI = debugInfo.UserLineToEndI(lineNumber);
            dataName = debugInfo.UserLineToDataNames(lineNumber);
            if contains(fcnName, ':')
                SfObjectName = fcnName;
            else
                realFcnName = fcnName;
                locationsOfUnderscore = strfind(realFcnName,'_');
                locationsOfDot = strfind(realFcnName,'.');
                assert((isempty(locationsOfDot) || locationsOfDot(1) <= 0 || ~isequal(modelNameForFcnPrefix, realFcnName(1:locationsOfDot(1)-1))) == false, 'wrong sfx object link');
                if fcnType == 1
                    SfObjectName = ['Function:' realFcnName(locationsOfDot(1) + 1 : end)];
                elseif fcnType == 2
                    SfObjectName = ['EMFunction:' realFcnName(locationsOfDot(1) + 1 : end)];
                elseif objType == 1 || objType == 2 || objType == 3
                    SfObjectName = ['Transition:' realFcnName(locationsOfDot(1) + 1 : locationsOfUnderscore(end - 2) - 1)];
                elseif objType == 4 || objType == 5 || objType == 6 || objType == 7
                    SfObjectName = ['State:' realFcnName(locationsOfDot(1) + 1 : locationsOfUnderscore(end - 2) - 1)];
                elseif objType == 19 %Data Initialization
                    SfObjectName = ['DataInitialization:' dataName];
                end
            end
            if objType == 19
                SfObjectLink = ['<a href="matlab: Stateflow.App.Cdr.Utils.openAndHighlightDataInSymbolsWindow(''' modelName ''',''' num2str(ssid) ''')">' dataName '</a>'];
            else
                SfObjectLink = ['<a href="matlab: Stateflow.App.Cdr.Utils.sfxCustomLink(''' Stateflow.App.Utils.escapeBackslash(filePath) ''',' num2str(ssid) ',' num2str(lineNo) ',' num2str(startI) ',' num2str(endI) ')">' SfObjectName '</a>'];
            end
            return;
        end

        function dataValue = getStringRepresentationOfData(val)
            szs = size(val);
            shorten = false;
            if (length(szs) > 2) || (szs(1) ~= 1)
                shorten = true;
            elseif isnumeric(val) || islogical(val)
                dataValue = num2str(val);
                if max(szs) > 42
                    shorten = true;
                end
            elseif ischar(val)
                [shorten, dataValue] = getStringRepresentationOfDataHelper(val, '''');
            elseif isstring(val) && max(szs) == 1
                [shorten, dataValue] = getStringRepresentationOfDataHelper(val, '"');
            else
                shorten = true;
            end
            if shorten
                dataValue = [strjoin(cellfun(@num2str, num2cell(szs), 'UniformOutput', false), 'x') ' ' class(val)];
            end

            function [shorten, dataValue] = getStringRepresentationOfDataHelper(d, sep)
                shorten = false;
                dataValue = '';
                valAsChar = char(d);
                if any(ismember(valAsChar, char([10 13])))
                    % XXX extend this to all non-printable characters
                    shorten = true;
                else
                    dataValue = [sep, valAsChar, sep];
                    if numel(dataValue) >= 42
                        shorten = true;
                        dataValue = '';
                    end
                end
            end
        end

        function retVal = isFilePartOfRuntime(filePath, fileName)
            retVal = contains(filePath, ['+Stateflow' filesep, '+App']);
            retVal = retVal || startsWith(fileName, 'Stateflow.App');
        end

        function logDataFcnHelper(this, dataVal, dataName) %#ok<INUSL>
            if(isempty(coder.target))
                for counterVal = 1:length(dataVal)
                    eval(['if isempty(this.' dataVal{counterVal} ')' newline 'this.' dataName '{counterVal} =[this.' dataName '{counterVal} {[]}];' newline 'else' newline 'this.' dataName '{counterVal} = [this.' dataName '{counterVal} ,{ this.' dataVal{counterVal} '}];' newline 'end' newline '']);
                end
            end
        end


    end
end

% LocalWords:  coverageexception Whitebox
