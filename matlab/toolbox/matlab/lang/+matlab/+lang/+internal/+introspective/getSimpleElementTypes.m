function elementTypes = getSimpleElementTypes
%

%   Copyright 2013-2020 The MathWorks, Inc.

    elementTypes = struct(...
        'keyword', {'properties', 'events', 'enumeration'}, ...
        'list', {'PropertyList', 'EventList', 'EnumerationMemberList'}, ...
        'node',  {'property-info', 'event-info', 'enumeration-info'});
end
