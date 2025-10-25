function helpview(topicId)
%This function is for internal use only. It may be removed in the future.

%helpview - Invoke Doc Browser for specified topicId

%   Copyright 2014-2023 The MathWorks, Inc.

topicId = convertStringsToChars(topicId);
validateattributes(topicId, {'char'}, {'nonempty'});
helpview('ros', topicId);
