function release = Release()
    persistent matlabReleaseRelease;
    if isempty(matlabReleaseRelease)
        matlabReleaseRelease = matlab.internal.matlabRelease.release;
    end
    release = matlabReleaseRelease;
end