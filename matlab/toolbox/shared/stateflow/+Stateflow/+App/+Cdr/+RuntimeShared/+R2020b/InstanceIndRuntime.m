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
        function parseArguments(varargin)
            Stateflow.App.Cdr.RuntimeShared.R2020b.parseArguments(varargin{:});
        end
        function processEventQueue(varargin)
            Stateflow.App.Cdr.RuntimeShared.R2020b.processEventQueue(varargin{:});
        end
        function pushToEventQueue(sfxObject, methodName, varargin)
            Stateflow.App.Cdr.RuntimeShared.R2020b.pushToEventQueue(sfxObject, methodName,  varargin(:));
        end
        function dispHelper(sfxObject, objectName)
            Stateflow.App.Cdr.RuntimeShared.R2020b.dispHelper(sfxObject, objectName);
        end
    end
    methods(Static)
        function retval = instance(varargin)
            persistent obj
            if isempty(obj)
                obj = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime;
                obj.commonUtils = Stateflow.internal.getCommonUtils();
                obj.externalSimCurrentTime = -1;
                obj.testingForMATLABInstall = false;
                obj.runtimeExceptionStacks = [];
            end
            retval = obj;
        end

        function callMethod(methodName, varargin)
            for forCounter = 1:length(varargin)
                switch methodName
                  case {'dispHelper','parseArguments','getPOSIXTime','verifyForEmptyData'}
                    Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.(methodName)(varargin{:});
                  otherwise
                    %fail-silent
                end
            end
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

        function verifyForEmptyData(sfxObject, ~)
            if  ~sfxObject.StateflowInternalData.ConfigurationOptions.WarningOnUninitializedData || ~sfxObject.StateflowInternalData.ConfigurationOptions.ExecuteInitStep
                return;
            end
            if ~sfxObject.StateflowInternalData.ConfigurationOptions.EnableAnimation
                return;
            end
            emptyData = {};
            emptyDataNames ='';
            for counterVar = 1 : length(sfxObject.StateflowInternalConstData.AllDataName)
                if isempty(sfxObject.(sfxObject.StateflowInternalConstData.AllDataName{counterVar}))
                    emptyData{end+1} = sfxObject.StateflowInternalConstData.AllDataName{counterVar}; %#ok<AGROW>
                    ssId = sfxObject.StateflowInternalConstData.AllDataId{counterVar};
                    dataName = sfxObject.StateflowInternalConstData.AllDataName{counterVar};
                    link = ['<a href="matlab:Stateflow.App.Cdr.Utils.openAndHighlightDataInSymbolsWindow(''' sfxObject.StateflowInternalConstData.ChartName ''', ''' num2str(ssId) ''')">'''  dataName '''</a>'];
                    emptyDataNames = [emptyDataNames link ', ']; %#ok<AGROW>
                end
            end

            % populate warning message
            warnId = 'MATLAB:sfx:EmptyDataAfterInitialization';
            msg = getString(message(warnId, Stateflow.App.Utils.getChartHyperlink(sfxObject.StateflowInternalConstData.ChartName), emptyDataNames(1:end-2)));

            % throw warning
            if ~isempty(emptyData)
                Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwWarning(warnId, msg, sfxObject.StateflowInternalConstData.ChartName);
            end
        end


        %% temporalOperatorCallbackRouter
        function temporalOperatorCallbackRouter(src, ~)
            try
                if isa(src.UserData.sfxInstance, 'handle') && isvalid(src.UserData.sfxInstance)
                    sfKeywords = Stateflow.App.Utils.StateflowKeywords;
                    src.UserData.sfxInstance.(sfKeywords.timerCallback);
                end
            catch ME
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

        function objId = getSFXObjId()
            obj = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;
            obj.commonUtils.counter = obj.commonUtils.counter + 1;
            objId = obj.commonUtils.counter;
        end
        function clearCurrentInstance()
            runtimeH = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;
            runtimeH.commonUtils.currentInstanceId = [];
            runtimeH.commonUtils.currentInstance = [];
        end

        function ret = getCounter()
            runtimeH = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;
            ret = runtimeH.commonUtils.counter;
        end

        function objs = getNestedObjs(id)
            objs = {};
            runtimeH = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;

            if isKey(runtimeH.commonUtils.nestedObjects, id)
                objs = runtimeH.commonUtils.nestedObjects(id);
            end
        end
        function objs = resetNestedObjs(id)
            runtimeH = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;
            if isKey(runtimeH.commonUtils.nestedObjects, id)
                runtimeH.commonUtils.nestedObjects.remove(id);
            end
        end

        function retVal = getExternalSimCurrentTime()
            instH = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;
            retVal = instH.externalSimCurrentTime;
        end

        function setExternalSimCurrentTime(val)
            instH = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;
            if isempty(val) || ~isscalar(val) || ~isnumeric(val) || val < 0
                errMsg = 'Simulation time value must be scalar non-negative double.';
                Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwError('MATLAB:sfx:InvalidSimTime', errMsg, chartName, 'OnlyCMD');
            elseif val <= instH.externalSimCurrentTime
                errMsg = ['Current simulation time must be larger than previous value of ' num2str(val) '.' newline ...
                          'Use larger time value or reset previous stale value using, ' newline ... '
                          'Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.resetExternalSimCurrentTime()'];
                Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwError('MATLAB:sfx:InvalidSimTime', errMsg, chartName, 'OnlyCMD');
            end
            instH.externalSimCurrentTime = val;
        end
        function resetExternalSimCurrentTime()
            instH = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;
            instH.externalSimCurrentTime = -1;
        end
        function setTestingForMATLABInstall(val)
            obj = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;
            obj.testingForMATLABInstall = val;
        end
        function val = getTestingForMATLABInstall()
            obj = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;
            val = obj.testingForMATLABInstall;
        end
        function clearCache()
            obj = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;
            obj.commonUtils.counter = 0;
            obj.commonUtils.nestedObjects = containers.Map('KeyType', 'double', 'ValueType', 'any');
            obj.commonUtils.currentInstance = [];
            obj.commonUtils.currentInstanceId = [];
            obj.externalSimCurrentTime = -1;
            obj.testingForMATLABInstall = false;
        end
        function DebugEventCallback(fileName, ~)
            if ~isdeployed
                if ~Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.getTestingForMATLABInstall() && exist(fullfile(matlabroot, 'toolbox', 'stateflow', 'stateflow', '+Stateflow', '+App', 'IsStateflowApp.m'), 'file') %todo
                    disp(getString(message('MATLAB:sfx:LoadStateflowFirstToDebug', fileName)));
                else
                    disp(getString(message('MATLAB:sfx:StateflowNeededForDebug', fileName)));
                end
                matlab.internal.mvm.debug.enqueueDbstepOut;
                matlab.internal.mvm.debug.enqueueDbstep;
            end
        end
        function setRecursionLimit(val)
            staticRuntimeSharedH = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;
            staticRuntimeSharedH.recursionLimit = val;
        end
        function throwErrorForCoder(errId, msg,varargin)
        % this is used by parseConfigArguments to throw errors since by
        % the time of parseConfigArguments, sfxObject runtime is not
        % created.
            try
                error(errId, msg);
            catch ME
                ME.throwAsCaller();
            end

        end
        function throwWarningOnCMDWithoutStack(warnId, msg)
        % Do not use this directly.
        % Use Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwWarning
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
            if ~Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.getTestingForMATLABInstall() && exist('chartName', 'var')
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
            Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwErrorOnCMD(errId, errMsg, chartName, suppressStackOnCMD);
        end
        function throwErrorOnCMD(errId, errMsg, ~, suppressStackOnCMD)
        % Do not use this directly.
        % Use Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwError
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

            if ~Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.getTestingForMATLABInstall() && exist('chartName', 'var')
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
            Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwWarningOnCMDWithoutStack(warnId, msg);

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

        function currentTime = getPOSIXTime(~)
            currentTime= posixtime(datetime('now'));
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
                assert((isempty(locationsOfDot) || locationsOfDot(1) <= 0)  == false, 'wrong sfx object link');
                if fcnType == 1
                    SfObjectName = ['Function:' realFcnName(locationsOfDot(1) + 1 : end)];
                elseif fcnType == 2
                    SfObjectName = ['EMFunction:' realFcnName(locationsOfDot(1) + 1 : end)];
                elseif objType == 1 || objType == 2 || objType == 3
                    SfObjectName = ['Transition:' realFcnName(locationsOfDot(1) + 1 : locationsOfUnderscore(end) - 1)];
                elseif objType == 4 || objType == 5 || objType == 6 || objType == 7
                    SfObjectName = ['State:' realFcnName(locationsOfDot(1) + 1 : locationsOfUnderscore(end) - 1)];
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


    end
end

% LocalWords:  coverageexception Whitebox
