function date = Date()
    persistent matlabReleaseDate;
    if isempty(matlabReleaseDate)
        matlabReleaseDate = datetime(matlab.internal.matlabRelease.date,'InputFormat','yyyy-MM-dd');
    end
    date = matlabReleaseDate;
end