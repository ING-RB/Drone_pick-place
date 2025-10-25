function rptds = loadobj(S)
%

%   Copyright 2021-2022 The MathWorks, Inc.

    import matlab.io.datastore.internal.RepeatedDatastore

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > RepeatedDatastore.ClassVersion
            error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
        end
    end

    % Handle the possibility that the RepeatAllFcn is not in the struct.
    RepeatAllFcn = getRepeatAllFcn(S);

    % Reconstruct the object.
    % The UnderlyingDatastore gets reset during construction, so pass a different datastore
    % for now.
    rptds = RepeatedDatastore(arrayDatastore([]), S.RepeatFcn, ...
                              IncludeInfo=S.IncludeInfo, RepeatAllFcn=RepeatAllFcn);

    % Recover the iterator position.
    rptds.UnderlyingDatastore      = S.UnderlyingDatastore; % Needs to be manually set to avoid reset() during construction.
    rptds.UnderlyingDatastoreIndex = S.UnderlyingDatastoreIndex;
    rptds.InnerDatastore           = S.InnerDatastore;
    rptds.CurrentReadData          = S.CurrentReadData;
    rptds.CurrentReadInfo          = S.CurrentReadInfo;
    rptds.RepetitionIndices        = S.RepetitionIndices;
end

function fcn = getRepeatAllFcn(S)
    % RepeatedDatastore's ClassVersion=1 doesn't have the RepeatAllFcn
    % property. Just set the default RepeatAllFcn in that case.
    if S.ClassVersion < 2
        fcn = @matlab.io.datastore.internal.RepeatedDatastore.defaultRepeatAllFcn;
    else
        fcn = S.RepeatAllFcn;
    end
end
