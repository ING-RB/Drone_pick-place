classdef Animation < handle
%

%   Copyright 2018-2020 The MathWorks, Inc.

    properties
        sfxObj
        timerRuntime
        sfxObjId
        chartName
        isExecuting = false
        runtimeUtils
    end
    methods%(Access=private)
        function checkModelOpen(~)
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

        function notifyStartingExecution(obj, varargin)
            obj.timerRuntime = obj.sfxObj.StateflowInternalData.TimerRuntime;
            obj.isExecuting = true;
        end

        function notifyEndingExecution(self, applicationName, application, varargin)
            self.isExecuting = false;
        end

        function update_runtime(obj, objectName, chartInstance, isStart)
        end

        function exception = runtimeException(obj, ME)
            obj.isExecuting = false;
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
                                  (contains(instH.runtimeExceptionStacks.original(i).file,'+Stateflow')  && contains(instH.runtimeExceptionStacks.original(i).file,'+App')) ||...
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
                    exception = Stateflow.App.Cdr.RuntimeShared.R2020b.RuntimeException(ME);
                catch MENOOP
                    instH.runtimeExceptionStacks.original = MENOOP.stack;
                    instH.runtimeExceptionStacks.pruned = instH.runtimeExceptionStacks.original;
                    exception = Stateflow.App.Cdr.RuntimeShared.R2020b.RuntimeException(MENOOP);
                    errId = 'MATLAB:sfx:InternalError';
                    warning(errId, getString(message(errId, MENOOP.identifier, MENOOP.message)));
                end
            else
                exception = Stateflow.App.Cdr.RuntimeShared.R2020b.RuntimeException(ME);
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

    end
    methods
        function callMethod(this, methodName, varargin)
            for forCounter = 1:length(varargin)
                switch methodName
                  case {'checkModelOpen','make_active','make_inactive','make_active_once','notifyStartingExecution','notifyEndingExecution','runtimeException'}
                    this.(methodName)(varargin{:});
                  otherwise
                    %fail-silent
                end
            end
        end

        function obj = Animation(varargin)
            if length(varargin) < 2 || mod(length(varargin), 2) ~= 0
                error('invalid arguments');
            end
            for i = 1:2:length(varargin)
                switch varargin{i}
                  case '-sfxObject'
                    obj.sfxObj = varargin{i+1};
                    obj.chartName = obj.sfxObj.StateflowInternalConstData.ChartName;
                  case '-sfxName'
                    obj.chartName = varargin{i+1};
                end
            end
            obj.sfxObjId = [];
            obj.runtimeUtils = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;
        end

        function reset(~)
        end

        function delete(obj)            
            if ~isempty(obj.timerRuntime)
                obj.timerRuntime.delete;
            end
        end
    end
    methods (Static)
        function NOOPCallback(~,~)
        end
        function animationObj = getAnimationObj(varargin)
            [modelRunningIn, ~] = Stateflow.App.Utils.getVersion();
            tSfxObject = [];
            tExplicitBlackBoxRuntimeSelection = false;
            for forCounter = 1:2:length(varargin)
                switch varargin{forCounter}
                  case '-sfxObject'
                    tSfxObject = varargin{forCounter+1};
                  case '-explicitBlackBoxRuntimeSelection'
                    tExplicitBlackBoxRuntimeSelection = varargin{forCounter+1};
                end
            end
            assert(~isempty(tSfxObject),'input argument not valid');
            modelSavedIn = tSfxObject.StateflowInternalConstData.ModelSavedIn.mlVersion;
            modelSavedInDifferentRelease = modelSavedIn ~= modelRunningIn;
            tTestingBlackBoxRuntime = Stateflow.App.Cdr.RuntimeShared.(Stateflow.App.Utils.getValidBlackboxRuntime(modelSavedIn)).InstanceIndRuntime.getTestingForMATLABInstall();
            tImplicitBlackBoxRuntimeSelection =  isdeployed || tTestingBlackBoxRuntime || modelSavedInDifferentRelease;
            tRequireBlackBoxRuntime =  tExplicitBlackBoxRuntimeSelection || tImplicitBlackBoxRuntimeSelection ;
            if ~tRequireBlackBoxRuntime 
                stateflowLoaded = exist(fullfile(matlabroot, 'toolbox', 'stateflow', 'stateflow', '+Stateflow', '+App', 'IsStateflowApp.m'), 'file') && eval('Stateflow.App.Cdr.Utils.isStateflowLoaded()');            
                tRequireBlackBoxRuntime = ~stateflowLoaded;
            end
            modelSavedIn = Stateflow.App.Utils.getValidBlackboxRuntime(modelSavedIn);
            if tRequireBlackBoxRuntime
                animationObj = Stateflow.App.Cdr.RuntimeShared.(modelSavedIn).Animation(varargin{:});
            else
                animationObj = eval('Stateflow.App.Cdr.Runtime.Animation(varargin{:})');
                return;
            end
        end

    end
end

% LocalWords:  runtimeexception navdeep
