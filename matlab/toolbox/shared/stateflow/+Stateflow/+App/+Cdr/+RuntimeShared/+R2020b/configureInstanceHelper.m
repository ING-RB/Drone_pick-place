function retVal = configureInstanceHelper(this, clockSpeedUp_SFX, varargin)
%

%   Copyright 2019 The MathWorks, Inc.

    runtimeUtils = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;
    for i_SFX_48 = 1:2:length(varargin)
        j_SFX_50 = {'-enableAnimation', '-enableDataLogging', '-clockSpeedFactor', '-MATLABTimer', '-externalClock', '-executionTimeForTimers','-animationDelay'};
        for i_SFX_49 = 1:length(j_SFX_50)
            if strcmp(varargin{i_SFX_48}, j_SFX_50{i_SFX_49})==true
                break
            elseif i_SFX_49== length(j_SFX_50)
                runtimeUtils.throwError('MATLAB:sfx:Runtime:InvalidConfigurationValue', [varargin{i_SFX_48}, ' is not valid configuration option.'], 'dummyChartName', 'OnlyCMD');
            end
        end
        if strcmp(varargin{i_SFX_48}, '-enableAnimation') == true
            if length(varargin) > i_SFX_48  && islogical(varargin{i_SFX_48+1}) && isscalar(varargin{i_SFX_48+1}) && ~isempty(varargin{i_SFX_48+1})
                this.sfInternalObj.enableAnimation = varargin{i_SFX_48+1};
            else
                runtimeUtils.throwError('MATLAB:sfx:Runtime:InvalidConfigurationValue', '-enableAnimation value must be logical non-empty scalar;', 'dummyChartName', 'OnlyCMD');
            end
        end
        if strcmp(varargin{i_SFX_48}, '-clockSpeedFactor') == true
            if length(varargin) > i_SFX_48  && isnumeric(varargin{i_SFX_48+1}) && isscalar(varargin{i_SFX_48+1}) && ~isempty(varargin{i_SFX_48+1})
                this.sfInternalObj.clockSpeedUp = varargin{i_SFX_48+1};
                this.(clockSpeedUp_SFX) = varargin{i_SFX_48+1};
            else
                runtimeUtils.throwError('MATLAB:sfx:Runtime:InvalidConfigurationValue', '-clockSpeedUp value must be double non-empty scalar;', 'dummyChartName', 'OnlyCMD');
            end
        end
        if strcmp(varargin{i_SFX_48}, '-animationDelay') == true
            if length(varargin) > i_SFX_48  && isnumeric(varargin{i_SFX_48+1}) && isscalar(varargin{i_SFX_48+1}) && ~isempty(varargin{i_SFX_48+1})
                this.sfInternalObj.animationDelay = varargin{i_SFX_48+1};
            else
                runtimeUtils.throwError('MATLAB:sfx:Runtime:InvalidConfigurationValue', '-animationDelay value must be double non-empty scalar;', 'dummyChartName', 'OnlyCMD');
            end
        end

        if strcmp(varargin{i_SFX_48}, '-enableDataLogging') == true
            if length(varargin) > i_SFX_48  && islogical(varargin{i_SFX_48+1}) && isscalar(varargin{i_SFX_48+1}) && ~isempty(varargin{i_SFX_48+1})
                this.sfInternalObj.enableDataLogging = varargin{i_SFX_48+1};
            else
                runtimeUtils.throwError('MATLAB:sfx:Runtime:InvalidConfigurationValue', '-enableDataLogging value must be logical non-empty scalar;', 'dummyChartName', 'OnlyCMD');
            end
        end
        if strcmp(varargin{i_SFX_48}, '-MATLABTimer') == true
            if length(varargin) > i_SFX_48  && islogical(varargin{i_SFX_48+1}) && isscalar(varargin{i_SFX_48+1}) && ~isempty(varargin{i_SFX_48+1})
                this.sfInternalObj.useMATLABTimerForSFTemporals = varargin{i_SFX_48+1};
            else
                runtimeUtils.throwError('MATLAB:sfx:Runtime:InvalidConfigurationValue', '-MATLABTimer value must be logical non-empty scalar;', 'dummyChartName', 'OnlyCMD');
            end
        end
        if strcmp(varargin{i_SFX_48}, '-externalClock') == true
            if length(varargin) > i_SFX_48  && islogical(varargin{i_SFX_48+1}) && isscalar(varargin{i_SFX_48+1}) && ~isempty(varargin{i_SFX_48+1})
                this.sfInternalObj.externalClock = varargin{i_SFX_48+1};
            else
                runtimeUtils.throwError('MATLAB:sfx:Runtime:InvalidConfigurationValue', '-externalClock value must be logical non-empty scalar;', 'dummyChartName', 'OnlyCMD');
            end
        end
        if strcmp(varargin{i_SFX_48}, '-executionTimeForTimers') == true
            if length(varargin) > i_SFX_48  && islogical(varargin{i_SFX_48+1}) && isscalar(varargin{i_SFX_48+1}) && ~isempty(varargin{i_SFX_48+1})
                this.sfInternalObj.executionTimeForTimers = varargin{i_SFX_48+1};
            else
                runtimeUtils.throwError('MATLAB:sfx:Runtime:InvalidConfigurationValue', '-executionTimeForTimers value must be logical non-empty scalar;', 'dummyChartName', 'OnlyCMD');
            end
        end
    end
    retVal = this;
end
