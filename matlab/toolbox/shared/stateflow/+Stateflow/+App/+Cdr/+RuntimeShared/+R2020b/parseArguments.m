function parseArguments(aSfxObject, aCalledFromConstructor, aNumberOutput, varargin)
    %@todo: varargin with name value pair for first three arguments at callsite

%   Copyright 2019-2020 The MathWorks, Inc.

    if aCalledFromConstructor
        parseArgumentsFromMATLABConstructor(aSfxObject, aNumberOutput, varargin{:});
    else
        parseArgumentsFromMATLABStep(aSfxObject, varargin{:});
    end
end

function msgWithHelpText = addHelpTextToMsg(aMsg, aSfxObject)
    msgWithHelpText = [aMsg newline eval(['help(''' aSfxObject.StateflowInternalConstData.ChartName ''')'])];         
end

function parseArgumentsFromMATLABConstructor(aSfxObject, aNumberOutput, varargin)
    
    if aNumberOutput ~= 1
        errId = 'MATLAB:sfx:ConstructorOutputMismatch';
        msg = getString(message(errId, aSfxObject.StateflowInternalConstData.ChartName, num2str(aNumberOutput)));
        msg = addHelpTextToMsg(msg, aSfxObject);
        Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwError(errId, msg, aSfxObject, 'OnlyCMD');
    end
    if mod(length(varargin), 2) ~= 0
        errId = 'MATLAB:sfx:InvalidConstructorArgumentNameWithNoValue';
        msg = getString(message(errId, length(varargin), aSfxObject.StateflowInternalConstData.ChartName));
        msg = addHelpTextToMsg(msg, aSfxObject);        
        Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwError(errId, msg, aSfxObject, 'OnlyCMD');
    end
    
    errId =  'MATLAB:sfx:InvalidConstructorArgument';
    
    for counterVar = 1:2:length(varargin)
        switch varargin{counterVar}
            %@TODO: move configuration names to a single place
            case aSfxObject.StateflowInternalConstData.AllDataName
            case {'-executeInitStep','-warningOnUninitializedData','-enableAnimation','-MATLABTimer'}
                if ~islogical(varargin{counterVar + 1})
                    msg = getString(message(errId, counterVar + 1, aSfxObject.StateflowInternalConstData.ChartName));
                    msg = addHelpTextToMsg(msg, aSfxObject);
                    Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwError(errId, msg, aSfxObject, 'OnlyCMD');
                end
                aSfxObject.StateflowInternalData.ConfigurationOptions.([upper(varargin{counterVar}(2)) varargin{counterVar}(3:end)]) = varargin{counterVar + 1};
            case {'-animationDelay','-eventQueueSize',}
                if ~isnumeric(varargin{counterVar + 1}) || ...
                        ~isscalar(varargin{counterVar + 1}) ...
                        || round(varargin{counterVar + 1},0) ~= varargin{counterVar + 1}
                    % Previous check (i.e. round...) differentiates between a double & an integer.
                    % e.g. foo('-eventQueueSize', 3), here value 3 is considered as double by MATLAB.
                    % Hence we cannot use isa(3, 'integer')
                    msg = getString(message(errId, counterVar + 1, aSfxObject.StateflowInternalConstData.ChartName));
                    msg = addHelpTextToMsg(msg, aSfxObject);                    
                    Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwError(errId, msg, aSfxObject, 'OnlyCMD');
                end
                aSfxObject.StateflowInternalData.ConfigurationOptions.([upper(varargin{counterVar}(2)) varargin{counterVar}(3:end)]) = varargin{counterVar + 1};
            otherwise
                msg = getString(message(errId, counterVar, aSfxObject.StateflowInternalConstData.ChartName));
                msg = addHelpTextToMsg(msg, aSfxObject);                    
                Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwError(errId, msg, aSfxObject, 'OnlyCMD');
        end
    end
    if aSfxObject.StateflowInternalData.ConfigurationOptions.EnableAnimation
        delete(aSfxObject.StateflowInternalData.AnimationRuntime);
        confMgr = Stateflow.App.Cdr.CdrConfMgr.getInstance;        
        aSfxObject.StateflowInternalData.AnimationRuntime = eval([confMgr.animationClass '(''-runtimeType'',''AnimationRuntime'',''-sfxObject'', aSfxObject, ''-explicitBlackBoxRuntimeSelection'', false)']);
    end
end
function parseArgumentsFromMATLABStep(aSfxObject, varargin)
    errId =  'MATLAB:sfx:InvalidConstructorArgument';
    if mod(length(varargin), 2) ~= 0
        errId = 'MATLAB:sfx:InvalidConstructorArgumentNameWithNoValue';
        msg = getString(message(errId, length(varargin), aSfxObject.StateflowInternalConstData.ChartName));
        msg = addHelpTextToMsg(msg, aSfxObject);
        Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwError(errId, msg, aSfxObject, 'OnlyCMD');
    end    
    for counterVar = 1 :2: length(varargin)
        switch varargin{counterVar}
            case aSfxObject.StateflowInternalConstData.AllDataName
                aSfxObject.set(varargin{counterVar},  varargin{counterVar+1});
            otherwise
                msg = getString(message(errId, counterVar, aSfxObject.StateflowInternalConstData.ChartName));
                msg = addHelpTextToMsg(msg, aSfxObject);
                Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwError(errId, msg, aSfxObject, 'OnlyCMD');
        end
    end
end


