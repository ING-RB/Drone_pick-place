function obj = getRuntime(varargin)
%

%   Copyright 2019-2020 The MathWorks, Inc.
%

%#codegen
    if ~isempty(coder.target)
        for forCounter = 1:2:length(varargin)
            switch varargin{forCounter}
              case '-runtimeType'
                tRuntimeType = varargin{forCounter+1};
              case '-sfxObject'
                tSfxObject = varargin{forCounter+1}; %#ok<NASGU>
            end
        end
        switch tRuntimeType
          case 'SharedRuntime'
            obj = Stateflow.App.Utils.Coder.InstanceIndRuntime.instance();
          case 'TimerRuntime'
            obj = Stateflow.App.Utils.Coder.Timer();
          case 'AnimationRuntime'
            obj = Stateflow.App.Utils.Coder.Animation();
          otherwise
            obj = Stateflow.App.Utils.Coder.FallbackNoSideEffectRuntime();
        end
        return;
    end
    if isdeployed
        for forCounter = 1:2:length(varargin)
            switch varargin{forCounter}
              case '-runtimeType'
                tRuntimeType = varargin{forCounter+1};
              case '-sfxObject'
                tSfxObject = varargin{forCounter+1}; %#ok<NASGU>
            end
        end
        switch tRuntimeType
          case 'SharedRuntime'
            obj = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance(varargin{:});
          case 'TimerRuntime'
            obj = Stateflow.App.Cdr.RuntimeShared.R2020b.Timer(varargin{:});
          case 'AnimationRuntime'
            obj = Stateflow.App.Cdr.RuntimeShared.R2020b.Animation(varargin{:});
          otherwise
            obj = Stateflow.App.Cdr.RuntimeShared.R2020b.FallbackNoSideEffectRuntime();
        end
        return;
    end
    try %#ok<*EMTC>
        tSfxObject = [];
        if isempty(varargin)
            [modelRunningIn, ~] = Stateflow.App.Utils.getVersion();
            obj = Stateflow.App.Cdr.RuntimeShared.(Stateflow.App.Utils.getValidBlackboxRuntime(modelRunningIn)).InstanceIndRuntime.instance;
            return;
        end
        for forCounter = 1:2:length(varargin)
            switch varargin{forCounter}
              case '-runtimeType'
                tRuntimeType = varargin{forCounter+1};
              case '-sfxObject'
                tSfxObject = varargin{forCounter+1};
            end
        end
        assert(~isempty(tSfxObject),'input argument not valid');
        modelSavedIn = tSfxObject.StateflowInternalConstData.ModelSavedIn.mlVersion;
        modelSavedIn = Stateflow.App.Utils.getValidBlackboxRuntime(modelSavedIn);
        switch tRuntimeType
          case 'SharedRuntime'
            obj = Stateflow.App.Cdr.RuntimeShared.(modelSavedIn).InstanceIndRuntime.instance(varargin{:});
          case 'TimerRuntime'
            obj = Stateflow.App.Cdr.RuntimeShared.(modelSavedIn).Timer(varargin{:});
          case 'AnimationRuntime'
            obj = Stateflow.App.Cdr.RuntimeShared.(modelSavedIn).Animation.getAnimationObj(varargin{:});
          otherwise
            obj = Stateflow.App.Cdr.RuntimeShared.(modelSavedIn).FallbackNoSideEffectRuntime;

        end

    catch ME %#ok<NASGU>
        errId = 'MATLAB:sfx:VersionMismatch';
        [modelRunningIn, ~] = Stateflow.App.Utils.getVersion();
        Stateflow.App.Cdr.RuntimeShared.(modelRunningIn).InstanceIndRuntime.throwError(errId, getString(message(errId,class(tSfxObject))), 'dummyChartName', 'OnlyCMD');
    end
end
