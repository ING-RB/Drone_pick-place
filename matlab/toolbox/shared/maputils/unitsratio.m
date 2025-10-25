function ratio = unitsratio(to, from)
%UNITSRATIO Unit conversion factors
%
%   RATIO = UNITSRATIO(TO, FROM) returns the number of TO units per one
%   FROM unit.  For example, UNITSRATIO('cm', 'm') returns 100 because
%   there are 100 centimeters per meter.  UNITSRATIO makes it easy to
%   convert from one system of units to another.  Specifically, if X is
%   in units FROM and Y is in units TO, then the conversion equation is
%
%                  Y = UNITSRATIO(TO, FROM) * X.
%
%   TO and FROM may be any of the length units supported by
%   validateLengthUnit, or may be one of the following angle units:
%
%     Angle Unit            Valid Inputs
%     ----------            ------------
%     radian               'rad', 'radian', 'radians'
%     degree               'deg', 'degree', 'degrees'
%
%   Examples
%   --------
%   % Approximate mean earth radius in meters
%   radiusInMeters = earthRadius('meters')
%   % Conversion factor
%   feetPerMeter = unitsratio('feet', 'meter')
%   % Radius in (international) feet:
%   radiusInFeet = feetPerMeter * radiusInMeters
%
%   % The following prints a true statement for any valid TO, FROM pair:
%   to   = 'feet';
%   from = 'mile';
%   sprintf('There are %g %s per %s.', unitsratio(to,from), to, from)
%
%   % The following prints a true statement for any valid TO, FROM pair:
%   to   = 'degrees';
%   from = 'radian';
%   sprintf('One %s is %g %s.', from, unitsratio(to,from), to)
%
%   See also validateLengthUnit.

% Copyright 2002-2017 The MathWorks, Inc.

% Ensure valid text inputs.
if nargin > 0
    to = convertStringsToChars(to);
end
if nargin > 1
    from = convertStringsToChars(from);
end
validateattributes(to,  {'char','string'},{'nonempty','scalartext'},'UNITSRATIO','TO',1)
validateattributes(from,{'char','string'},{'nonempty','scalartext'},'UNITSRATIO','FROM',2)

% Validate units and convert to standard names.
degreeStrings = {'deg','degree','degrees'};
radianStrings = {'rad','radian','radians'};

try
    to = validateLengthUnit(to,'UNITSRATIO','TO',1);
catch exception
    if any(strcmpi(to, degreeStrings))
        to = 'degree';
    elseif any(strcmpi(to, radianStrings))
        to = 'radian';
    else
        exception.throw()
    end
end

try
    from = validateLengthUnit(from,'UNITSRATIO','FROM',2);
catch exception
    if any(strcmpi(from, degreeStrings))
        from = 'degree';
    elseif any(strcmpi(from, radianStrings))
        from = 'radian';
    else
        exception.throw()
    end
end


% Define a relationship graph by specifying a scaling factor for each pair
% of adjacent units (using the standard names). Each unit on the left is
% defined in terms of the unit on the right via the factor provided, which
% is the value that will be returned by unitsratio(RIGHT, LEFT). For
% example, unitsratio('meter','micron') returns 1e-6.
graph = {...
    'micron',             'meter',   1e-6;
    'millimeter',         'meter',   1e-3; ...
    'centimeter',         'meter',   1e-2; ...
    'kilometer',          'meter',   1e+3; ...
    'nautical mile',      'meter',   1852; ...
    'foot',               'meter',   0.3048; ...
    'mile',               'foot',    5280; ...
    'inch',               'foot',    1/12; ...
    'yard',               'foot',    3; ...
    'U.S. survey foot',   'meter',   1200/3937; ...
    'U.S. survey mile',   'U.S. survey foot', 5280; ...
    'Clarke''s foot',     'meter',   0.3047972654; ...
    'German legal metre', 'meter',   1.0000135965; ...
    'Indian foot',        'meter',   12/39.370142; ...
    'degree',             'radian',  pi/180 ...
    };

% Do a depth-first search of the directed graph corresponding
% to the definitions array, recursively searching for a
% path from FROM to TO.
ratio = searchgraph(to, from, graph, {});

% A return value of NaN in RATIO indicates that no connection exists.
if isnan(ratio)
    error(message('maputils:unitsratio:unableToConvertUnits', to, from)) 
end

%-------------------------------------------------------------------

function [ratio, history] = searchgraph(to, from, graph, history)

% Assume a dead-end unless/until a path is found from FROM to TO.
ratio = NaN;

% Stop here if FROM has already been checked (avoid loops in the graph).
if any(strcmp(from,history))
    return;
end

% Append FROM to the list of nodes that have been visited.
history{end+1} = from;

% Find occurrences of FROM and TO in columns 1 and 2 of GRAPH.
from1 = find(strcmp(from, graph(:,1)));
from2 = find(strcmp(from, graph(:,2)));
to1   = find(strcmp(to,   graph(:,1)));
to2   = find(strcmp(to,   graph(:,2)));

% See if there's a direct conversion from TO to FROM:
% If there's a row with TO in column 1 and FROM in column 2, then
% column 3 of that row contains the conversion factor
% from FROM to TO.
i = intersect(to1, from2);
if numel(i) == 1
    ratio = 1 / graph{i,3};
    return;
end

% See if there's a direct conversion from FROM to TO:
% If there's a row with FROM in column 1 and TO in column 2,
% then column 3 of that row contains the conversion factor.
i = intersect(to2, from1);
if numel(i) == 1
    ratio = graph{i,3};
    return;
end

% Recursively search for conversion to TO from each node adjacent
% to FROM.

% Search from the adjacent nodes with a direct conversion _from_
% FROM.  If a conversion factor (non-NaN) to TO is found from
% one of these adjacent nodes, then multiply it by the conversion
% factor from FROM to that neighbor (divide by the defining
% factor in column 3 of GRAPH).
for i = 1:numel(from2)
   n = from2(i);
   [ratio, history] = searchgraph(to, graph{n,1}, graph, history);
   if ~isnan(ratio)
       ratio = ratio / graph{n,3};
       return;
   end
end

% Search from the adjacent nodes with a direct conversion _to_ FROM.
% If a conversion factor (non-NaN) to TO is found from one of these
% adjacent nodes, then divide it by the conversion factor from FROM
% to that neighbor (multiply by the defining factor in column 3).
for i = 1:numel(from1)
   n = from1(i);
   [ratio, history] = searchgraph(to, graph{n,2}, graph, history);
   if ~isnan(ratio)
       ratio = ratio * graph{n,3};
       return;
   end
end
