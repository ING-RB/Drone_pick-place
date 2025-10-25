function ds = logCommunication(location, varargin)
% Annotate execution of a tall array to generate a log of all communication
% that occurs during evaluation of a tall array expression.
%
% Syntax:
%   matlab.bigdata.internal.debug.logCommunication(LOCATION) enables
%   logging of all communication to the given location.
%
%   matlab.bigdata.internal.debug.logCommunication('off') disables logging
%   of communication.
%
%   ds = matlab.bigdata.internal.debug.logCommunication('datastore') returns a
%   datastore to the log entries. This also disables logging of
%   communication.
%
% This will generate a timetable of log entries, each row corresponding to
% a single piece of communication. This has the following variables:
%
%       TaskId: A unique ID attached to the piece of execution prior to
%          communication.
%       Source: A string representing the source of the communication, e.g.
%          "Partition 3".
%  Destination: A string representing the destination of the communication,
%               e.g  "Partition 1", "Broadcast" or "Client".
%     NumBytes: The number of bytes being transferred.
%
% The source and destination strings can have the following values:
%   "Partition N": The worker dealing with the partition of index N.
%        "Client": The client MATLAB.
%     "Broadcast": Everywhere. Some back-ends optimize this to just the
%                client.
%
% Example:
%
%   ds = tabularTextDatastore(repmat({'airlinesmall.csv'}, 10, 1), ...
%       'TreatAsMissing', 'NA', 'SelectedVariableNames', {'ArrDelay'});
%   tt = tall(ds);
%
%   matlab.bigdata.internal.debug.logCommunication(tempname);
%   gather(mean(tt.ArrDelay, 'omitnan'));
%   logDs = matlab.bigdata.internal.debug.logCommunication('datastore');
%
%   log = tall(logDs);
%   display(gather(sum(log.NumBytes)));
%

%   Copyright 2017-2018 The MathWorks, Inc.

import matlab.bigdata.internal.debug.CommunicationLogger;

persistent LOGGER_OBJECT
persistent LOG_LOCATION

delete(LOGGER_OBJECT);
LOGGER_OBJECT = [];
mlock;

if location == "datastore"
    assert(~isempty(LOG_LOCATION), 'Communication logger was not active.');
    ds = datastore(LOG_LOCATION);
elseif location ~= "off"
    location = iParseLocation(location);
    LOGGER_OBJECT = CommunicationLogger(location, varargin{:});
    LOG_LOCATION = [LOGGER_OBJECT.OutputFolder, '/*/*/*'];
end

function location = iParseLocation(location)
% Parse the location to a path that can be used for logging. This will
% create a unique subfolder of the provided path already exists.
if matlab.io.datastore.internal.isIRI(location)
    return;
end
if exist(location, 'dir')
    for ii = 1:flintmax
        newLocation = sprintf('%s/%i', location, ii);
        if ~exist(newLocation, 'dir')
            location = newLocation;
            break;
        end
    end
end
mkdir(location);
