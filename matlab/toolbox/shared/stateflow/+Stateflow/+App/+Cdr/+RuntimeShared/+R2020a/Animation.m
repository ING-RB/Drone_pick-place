classdef Animation < handle
%

%   Copyright 2018-2019 The MathWorks, Inc.

    properties
        sfxObj
        timerRuntime
        sfxObjId
        chartName
        isExecuting = false
        runtimeUtils
    end
    methods

        function checkModelOpen(~)
        end

        function obj = Animation(machineName)
            obj.chartName= machineName;
            obj.sfxObj = [];
            obj.sfxObjId = [];
            obj.runtimeUtils = Stateflow.App.Cdr.RuntimeShared.R2020a.InstanceIndRuntime.instance;
        end
        function isEnabled = make_active(obj,ssId) %#ok<*INUSD>
            isEnabled = false;
        end

        function isEnabled = make_active_once(obj,ssId)
            isEnabled = false;
        end

        function isEnabled = make_inactive(obj,ssId)
            isEnabled = false;
        end

        function notifyStartingExecution(obj, ~, application, varargin)
            obj.runtimeUtils.checkRecursionLimitReached();
            obj.sfxObj = application;
            obj.isExecuting = true;
            if ~isempty(obj.sfxObj)
                obj.sfxObjId = obj.runtimeUtils.setCurrentInstance(obj.sfxObj,obj.sfxObjId);
            end
            obj.sfxObj.sfInternalObj.enableAnimation = false;
            if ~isempty(obj.sfxObj) && isprop(obj.sfxObj, 'timerRuntime') && ~isempty(obj.sfxObj.timerRuntime)
                obj.timerRuntime = obj.sfxObj.timerRuntime;
            end
        end

        function notifyEndingExecution(self, applicationName, application, varargin)
            self.isExecuting = false;
            if ~isempty(self.sfxObjId)
                self.runtimeUtils.resetCurrentInstance(self.sfxObjId);
            end
        end

        function update_runtime(obj, objectName, chartInstance, isStart)
        end

        function reset(~)
        end

        function delete(obj)
            p = obj.runtimeUtils.getNestedObjs(obj.sfxObjId) ;
            for i = 1:length(p)
                if isa(p{i}, 'handle') && isvalid(p{i})
                    delete(p{i});
                end
            end

            if ~isempty(obj.timerRuntime) && ~isempty(obj.timerRuntime.timerObj)
                if isa(obj.timerRuntime.timerObj, 'handle') && isvalid(obj.timerRuntime.timerObj)
                    stop(obj.timerRuntime.timerObj);
                    funH = @obj.runtimeUtils.NOOPCallback;
                    obj.timerRuntime.timerObj.timerFcn = funH;
                    delete(obj.timerRuntime.timerObj);
                end

                if isa(obj.timerRuntime, 'handle') && isvalid(obj.timerRuntime)
                    delete(obj.timerRuntime);
                end
            end
        end

        function exception = runtimeException(obj, ME)
            obj.isExecuting = false;
            obj.runtimeUtils.resetCurrentInstance(obj.sfxObjId);
            instH = obj.runtimeUtils;
            confH = Stateflow.App.Cdr.CdrConfMgr.getInstance();
            instH.runtimeExceptionStacks.original = ME.stack;
            instH.runtimeExceptionStacks.pruned = instH.runtimeExceptionStacks.original;
            if ~isequal(ME.identifier, 'MATLAB:sfx:RecursionLimitReached')
                try
                    if isequal(confH.testingUnhandledErrors, 'runtimeexception')
                        disp(a(2));  %unhandled error for testing
                    end

                    currentSFXFileName = [];

                    prunedIdx = [];
                    for i = 1:length(instH.runtimeExceptionStacks.original)
                        if endsWith(instH.runtimeExceptionStacks.original(i).file,'.sfx')
                            if ~isequal(instH.runtimeExceptionStacks.original(i).file, currentSFXFileName)
                                %keep top sfx function call in call stack
                                currentSFXFileName = instH.runtimeExceptionStacks.original(i).file;
                            else
                                %prune subsequent sfx function call in call stack
                                prunedIdx = [prunedIdx i]; %#ok<AGROW>
                            end
                        elseif   (endsWith(instH.runtimeExceptionStacks.original(i).name,'Panel.callEventMethod') || ...
                                  endsWith(instH.runtimeExceptionStacks.original(i).name,'InstanceIndRuntime.temporalOperatorCallbackRouter')  ||...
                                  endsWith(instH.runtimeExceptionStacks.original(i).file,fullfile(matlabroot,'toolbox','matlab','iofun','timercb.m'))  ||...
                                  endsWith(instH.runtimeExceptionStacks.original(i).file,fullfile(matlabroot,'toolbox','simulink','simulink','+SLStudio','ToolBars.p')))
                            prunedIdx = [prunedIdx i+1:length(instH.runtimeExceptionStacks.original)];%#ok<AGROW>
                            break;
                        else
                            currentSFXFileName = [];
                        end
                    end
                    for i = length(prunedIdx):-1:1
                        instH.runtimeExceptionStacks.pruned(prunedIdx(i)) = [];
                    end
                    for i = length(instH.runtimeExceptionStacks.pruned):-1:1
                        if endsWith(instH.runtimeExceptionStacks.pruned(i).file, '.sfx')
                            [~, ~, ~, ~, ~, SfObjectName] = instH.getSFXObjectLink(instH.runtimeExceptionStacks.pruned(i).file, instH.runtimeExceptionStacks.pruned(i).name, instH.runtimeExceptionStacks.pruned(i).line);
                            instH.runtimeExceptionStacks.pruned(i).name = SfObjectName;
                            assert(instH.runtimeExceptionStacks.pruned(i).line > 0, 'line number should be positive integer');
                            if isequal(instH.runtimeExceptionStacks.pruned(i).name, 'SFX_Internal_Fcn')
                                instH.runtimeExceptionStacks.pruned(i) = [];
                            end
                        end
                    end
                    if isempty(instH.runtimeExceptionStacks.pruned)
                        instH.runtimeExceptionStacks.pruned = instH.runtimeExceptionStacks.original;%@todo navdeep if you run model for lvlTwo_VersionWarningOlder in actual command line, you hit this. but when it is run from test, it adds some stack to it hence does not reach here.
                    end
                    if ~isempty(instH.runtimeExceptionStacks.pruned)
                        instH.runtimeExceptionStacks.pruned = [instH.runtimeExceptionStacks.pruned(1);instH.runtimeExceptionStacks.pruned];
                    end

                    exception = Stateflow.App.Cdr.RuntimeShared.R2020a.RuntimeException(ME);
                catch MENOOP
                    instH.runtimeExceptionStacks.original = MENOOP.stack;
                    instH.runtimeExceptionStacks.pruned = instH.runtimeExceptionStacks.original;
                    exception = Stateflow.App.Cdr.RuntimeShared.R2020a.RuntimeException(MENOOP);
                    errId = 'MATLAB:sfx:InternalError';
                    warning(errId, getString(message(errId, MENOOP.identifier, MENOOP.message)));
                end
            else
                exception = Stateflow.App.Cdr.RuntimeShared.R2020a.RuntimeException(ME);
                if length(ME.stack) > 1
                    for i = 1:length(instH.runtimeExceptionStacks.original)
                        if instH.isFilePartOfRuntime(instH.runtimeExceptionStacks.original(i).file, instH.runtimeExceptionStacks.original(i).name)
                            continue;
                        end
                        [SfObjectLink, ~, ~, ~, ~, SfObjectName] = instH.getSFXObjectLink(instH.runtimeExceptionStacks.original(i).file, instH.runtimeExceptionStacks.original(i).name, instH.runtimeExceptionStacks.original(i).line);
                        if ~isempty(SfObjectLink)
                            instH.runtimeExceptionStacks.pruned = instH.runtimeExceptionStacks.original(i);
                            instH.runtimeExceptionStacks.pruned.name = SfObjectName;
                            break;
                        end
                    end
                    assert(length(instH.runtimeExceptionStacks.pruned) == 1);
                end
            end
        end

        function log_data(obj, dataName, stepIndex, dataValue)

        end
    end
    methods (Static)
        function obj = getAnimationObj(fileName,machineName, chartFileNumber, chartPath, explicitRuntimeSelection) %#ok<INUSL>
            obj = Stateflow.App.Cdr.RuntimeShared.R2020a.Animation(machineName);
        end        
        function NOOPCallback(~,~)
        end
    end


end

% LocalWords:  runtimeexception navdeep
