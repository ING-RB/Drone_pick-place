function S = saveobj(rptds)
%saveobj   Save-to-struct for RepeatedDatastore.

%   Copyright 2021-2022 The MathWorks, Inc.

    % Store save-load metadata.
    S = struct("EarliestSupportedVersion", 1);
    S.ClassVersion = rptds.ClassVersion;

    % Public properties
    S.UnderlyingDatastore      = rptds.UnderlyingDatastore;
    S.UnderlyingDatastoreIndex = rptds.UnderlyingDatastoreIndex;
    S.InnerDatastore           = rptds.InnerDatastore;
    S.IncludeInfo              = rptds.IncludeInfo;
    S.RepeatFcn                = rptds.RepeatFcn;
    S.RepeatAllFcn             = rptds.RepeatAllFcn;
    S.CurrentReadData          = rptds.CurrentReadData;
    S.CurrentReadInfo          = rptds.CurrentReadInfo;
    S.RepetitionIndices        = rptds.RepetitionIndices;
end
