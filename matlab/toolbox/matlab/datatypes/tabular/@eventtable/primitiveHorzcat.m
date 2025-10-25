function t2 = primitiveHorzcat(t1,varargin)
%PRIMITIVEHORZCAT Raw horizontal concatenation for event tables with no error checking.
%   T = PRIMITIVEHORZCAT(T1, T2, ...) horizontally concatenates the event tables T1,
%   T2, ... positionally w.r.t rows, without regard to any row labels other than
%   those in T1. All inputs are assumed to be the same height. All inputs must
%   be tabular, and are assumed to have the same row labels, or no row labels.
%   Variable names must not conflict. Mix of eventtables and timetables is
%   allowed but the output is always an eventtable.

%   Copyright 2022 The MathWorks, Inc.

% If we get dispatched to eventtable/primitiveHorzcat then there is at least one
% eventtable in the input list since it is superior to timetables and tables.
% Applying primitiveHorzcat to a list of timetables and eventtables should
% return an eventtable output. So if the first input happens to be a timetable,
% then convert it into an eventtable and then let tabular/primitiveHorzcat do
% the rest of the work.
if isa(t1,'timetable') && ~isa(t1,'eventtable')
    t1 = eventtable.initFromTimetable(t1);
end
t2 = primitiveHorzcat@tabular(t1,varargin{:});