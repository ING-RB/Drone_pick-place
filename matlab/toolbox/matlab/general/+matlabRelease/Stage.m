function stage = Stage()
    persistent matlabReleaseStage;
    if isempty(matlabReleaseStage)
        matlabReleaseStage = matlab.internal.matlabRelease.stage;
    end
    stage = matlabReleaseStage;
end