function tf = isequaln(rptds1, rptds2, varargin)
%isequaln   isequaln is overloaded for RepeatedDatastore to ignore the
%   RepeatFcn property.

%   Copyright 2021-2022 The MathWorks, Inc.

    % isequaln ignores RepetitionIndices since its populated in a
    % deferred manner.
    % CurrentReadData/CurrentReadInfo/UnderlyingDatastoreIndex is also
    % ignored since its expected to be compared through isequaln on the
    % UnderlyingDatastore.

    % Verify that the object classes are correct
    isRepeatedDs = @(x) isa(x, "matlab.io.datastore.internal.RepeatedDatastore");
    tf = isRepeatedDs(rptds1) && isRepeatedDs(rptds2) ...
       && isequaln(rptds1.UnderlyingDatastore, rptds2.UnderlyingDatastore) ...
       && isequaln(rptds1.InnerDatastore,      rptds2.InnerDatastore) ...
       && isequaln(rptds1.RepeatFcn,           rptds2.RepeatFcn) ...
       && isequaln(rptds1.RepeatAllFcn,        rptds2.RepeatAllFcn) ...
       && isequaln(rptds1.IncludeInfo,         rptds2.IncludeInfo);

    % Recurse for any other inputs.
    for index = 1:numel(varargin)
        tf = tf && isequaln(rptds1, varargin{index});
    end
end
