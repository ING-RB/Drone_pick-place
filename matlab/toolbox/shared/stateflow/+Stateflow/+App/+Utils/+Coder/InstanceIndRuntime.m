classdef InstanceIndRuntime < handle
    %

%   Copyright 2019-2020 The MathWorks, Inc.
    
    methods(Access=private)
        function obj = InstanceIndRuntime
        %

            %#codegen
            coder.internal.allowHalfInputs;
        end
    end
    methods(Static)
        function obj = instance
            %#codegen
            coder.internal.allowHalfInputs;
            obj = Stateflow.App.Utils.Coder.InstanceIndRuntime;
        end
        function parseArguments(aSfxObject, aCalledFromConstructor, aNumberOutput, varargin)
            if aCalledFromConstructor
                Stateflow.App.Utils.Coder.InstanceIndRuntime.parseArgumentsFromCoderConstructor(aSfxObject, aNumberOutput, varargin{:});
            else
                Stateflow.App.Utils.Coder.InstanceIndRuntime.parseArgumentsFromCoderStep(aSfxObject, varargin{:});
            end
        end
        function verifyForEmptyData(varargin)
        end
        function pushToEventQueue(varargin)
        end
        function processEventQueue(varargin)
        end
        function tReturnValue = getPOSIXTime(varargin)
            tReturnValue= 0;
            tFunctionLocalVariable = coder.opaque('time_t', '0');
            coder.cinclude("time.h");
            tReturnValue= coder.ceval('time', coder.wref(tFunctionLocalVariable));
        end

        function parseArgumentsFromCoderConstructor(aSfxObject, ~, varargin)
            if aSfxObject.StateflowInternalConstData.UseRealTimeTemporal
                warnId =  'MATLAB:sfx:MATLABCoderTemporalWarning';
                Stateflow.App.Utils.Coder.compileWarning(warnId, aSfxObject.StateflowInternalConstData.ChartLink);
            end
            if mod(length(varargin), 2) ~= 0
                errId = 'MATLAB:sfx:InvalidConstructorArgumentNameWithNoValue';
                coder.internal.errorIf(true, errId, length(varargin), aSfxObject.StateflowInternalConstData.ChartName);
            end
            
            errId = 'MATLAB:sfx:InvalidConstructorArgument';
            for counterVar1 = 1:2:length(varargin)
                switch varargin{counterVar1}
                    case aSfxObject.StateflowInternalConstData.LocalDataName
                    case {'-executeInitStep','-eventQueueSize','-warningOnUninitializedData','-enableAnimation','-animationDelay','-MATLABTimer'}
                        aSfxObject.StateflowInternalData.ConfigurationOptions.([upper(varargin{counterVar1}(2)) varargin{counterVar1}(3:end)]) = varargin{counterVar1 + 1};
                        if isequal(varargin{counterVar1},'-eventQueueSize')
                            warnId =  'MATLAB:sfx:MATLABCoderEventQueueWarning';
                            Stateflow.App.Utils.Coder.compileWarning(warnId, aSfxObject.StateflowInternalConstData.ChartLink);
                        end
                    otherwise
                        coder.internal.errorIf(true, errId, varargin{counterVar1}, aSfxObject.StateflowInternalConstData.ChartName);
                end
            end
        end
        
        function parseArgumentsFromCoderStep(aSfxObject, varargin)
            errId = 'MATLAB:sfx:InvalidConstructorArgument';
            for counterVar = 1:2:length(varargin)
                switch varargin{counterVar}
                    case aSfxObject.StateflowInternalConstData.LocalDataName
                        aSfxObject.set(varargin{counterVar},  varargin{counterVar+1});
                    otherwise
                        %@TODO unify error throwing for CODER and for MATLAB
                        coder.internal.errorIf(true, errId, aSfxObject.StateflowInternalConstData.uninitializedDataStr, aSfxObject.StateflowInternalConstData.ChartName);
                end
            end
        end
    end
end
