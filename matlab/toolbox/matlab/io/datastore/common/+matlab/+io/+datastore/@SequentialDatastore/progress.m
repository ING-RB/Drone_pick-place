function frac = progress(ds)
%PROGRESS   Percentage of consumed data between 0.0 and 1.0
%
%   Return a fraction between 0.0 and 1.0 indicating progress
%   as a double.
%
%   See also read, hasdata, reset, readall, preview

%   Copyright 2022 The MathWorks, Inc.

if ~hasdata(ds)
    % Progress is always 1 if there are no underlying datastores or no more
    % data to read. This helps provide an indicator that it is not valid to
    % call read on an empty SequentialDatastore.
    frac = 1;
else
    idx = ds.CurrentDatastoreIndex;
    currentDSProgress = progress(ds.UnderlyingDatastores{idx});

    % G2751481: special case to handle first empty underlying datastore.
    if idx == 1 && currentDSProgress ==  1
        % For first empty underlying datastore, treat its granular progress
        % as 0 to avoid having a progress equal to the fraction:
        % ds.CurrentDatastoreIndex/numel(ds.UnderlyingDatastores),
        % before actually reading the first underlying datastore (which is empty).
        % E.g.: progress value larger than 0 immediately after construction.
        copyCurrentDS = copy(ds.UnderlyingDatastores{ds.CurrentDatastoreIndex});
        reset(copyCurrentDS);
        if ~hasdata(copyCurrentDS)
            % Empty first underlying datastore, set progress to 0.
            frac = 0;
            return;
        end
    end

    overallProgressTillPreviousDS = (idx - 1) / numel(ds.UnderlyingDatastores);

    overallProgressPerDS = 1 / numel(ds.UnderlyingDatastores);
    % Find parts of progress of the current UnderlyingDatastore in overallProgressPerDS.
    currentDSProgressFrac = currentDSProgress * overallProgressPerDS;

    % Add to the overall progress completed.
    frac = overallProgressTillPreviousDS + currentDSProgressFrac;
end
end