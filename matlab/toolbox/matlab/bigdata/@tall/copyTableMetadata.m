function tX = copyTableMetadata(tX, tY, skipList)
%copyTableMetadata Copy table metadata from tY into tX
%   TX = copyTableMetadata(TX,TY) copies all metadata properties from table
%   or timetable TY into tabel or timetable TX. Inputs can be tall or
%   in-memory. Data properties (i.e. RowNames or RowTimes) are not copied.
%
%   TX = copyTableMetadata(TX,TY,SKIPLIST) copies all metadata properties
%   except those in SKIPLIST, which must be a string array of properties to
%   omit.
%
%   NB: By default the metadata includes per-variable data such as names,
%   units, etc. If you don't want those copied you need to add the to the
%   skip-list.

% Copyright 2018-2022 The MathWorks, Inc.

% First extract the properties from TY
tyProps = struct(subsref(tY, substruct('.', 'Properties')));

% Remove the properties we don't want to copy. These include the data
% properties RowNames and RowTimes, and also the non-supported properties
% for tall timetables.
nonSupportedProps = matlab.bigdata.internal.adaptors.TimetableAdaptor.listNonSupportedProperties();
toRemove = ["RowNames"; "RowTimes"; nonSupportedProps];

% Also remove any that the caller supplied
if nargin>2
    toRemove = [toRemove; skipList(:)];
end
toRemove = intersect(fields(tyProps), toRemove);

% Clear the fields we don't want
tyProps = rmfield(tyProps, toRemove);

% Set the entire properties struct in one go.
tX = subsasgn(tX, substruct(".", "Properties"), tyProps);