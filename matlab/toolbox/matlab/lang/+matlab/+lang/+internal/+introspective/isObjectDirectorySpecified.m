function b = isObjectDirectorySpecified(topic)
%

%   Copyright 2013-2020 The MathWorks, Inc.

    b = ~isempty(regexp(topic, '(^|[\\/])[@+]', 'once'));
end
