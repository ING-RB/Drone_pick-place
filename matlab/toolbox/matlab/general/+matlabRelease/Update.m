function update = Update()
    persistent matlabReleaseUpdate;
    if isempty(matlabReleaseUpdate)
        matlabReleaseUpdate = matlab.internal.matlabRelease.update;
    end
    update = matlabReleaseUpdate;
end