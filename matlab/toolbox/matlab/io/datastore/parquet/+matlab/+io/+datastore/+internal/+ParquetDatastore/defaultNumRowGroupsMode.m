function tf = defaultNumRowGroupsMode(tf)
%defaultNumRowGroupsMode   Sets and gets the default sync/async NumRowGroups
%   computation mode.
%
%      import matlab.io.datastore.internal.ParquetDatastore.defaultNumRowGroupsMode
%
%      % Get the NumRowGroups mode for ParquetDatastore.
%      TF = defaultNumRowGroupsMode();     % Returns false (asynchronous by default).
%
%      % Set the NumRowGroups mode for ParquetDatastore.
%      TF = defaultNumRowGroupsMode(true); % Sets the synchronous mode.

%   Copyright 2022 The MathWorks, Inc.

    persistent useSync

    if isempty(useSync)
        % Use the asynchronous NumRowGroups calculation by default.
        useSync = false;
    end

    if nargin > 0
        % Override with the value supplied by the user.
        validateattributes(tf, "logical", "scalar");
        useSync = tf;
    end

    tf = useSync;
end