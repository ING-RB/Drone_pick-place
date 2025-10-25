% mustBeMemberCaseInsensitive Utility function to validate input is a
% member of a given set, case insensitive

%   Copyright 2019-2020 The MathWorks, Inc.

function mustBeMemberCaseInsensitive(value, set)
    mustBeMember(lower(value), lower(set));
end
