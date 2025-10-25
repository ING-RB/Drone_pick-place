function ret = addCursor(p,ang,datasetIdx)
%addCursor Add cursor to plot.
%   addCursor(p,ang) adds a cursor to the active trace, at the
%   data point closest to the specified angle (angle is in
%   user-space degrees)
%
%   addCursor(p,ang,idx) adds a cursor to the specified dataset
%   index, or to the active trace if idx = [].
%
%   ID = addCursor(...) optionally returns a cell string with
%   one ID for each cursor created.
%
%   Both ang and idx may be vectors with the same length, or
%   one may be a scalar.
%
%  See also polarpattern, <a href="matlab:help internal.polari.Peaks">Peaks</a>.

% Create indexing increment for scalar/vector inc_a argument:
if isscalar(ang)
    inc_a = 0;
else
    inc_a = 1;
end
i_a = 1;

% Support scalar expansion of datasetIdx:
%  - if empty or a scalar, use that for all cursors
%  - if a vector, ensure it's the same length as ang
if nargin < 3
    datasetIdx = []; % active dataset
end
if isempty(datasetIdx) || isscalar(datasetIdx)
    inc_d = 0;
else
    if (inc_a==1) && numel(datasetIdx) ~= numel(ang)
        error(message('siglib:polarpattern:LengthSame'));
        %error('datasetIdx must have the same length as ang');
    end
    inc_d = 1;
end
i_d = 1;

Na = numel(ang);
id = cell(1,Na);
for i = 1:Na
    ang_i = ang(i_a);
    i_a = i_a + inc_a;
    
    if inc_d==0
        ds_i = datasetIdx; % works for empty datasetIdx
    else
        ds_i = datasetIdx(i_d);
        i_d = i_d + inc_d;
    end
    
    % Returns empty if this fails to add cursor, due to no data
    m = addCursorAllArgs(p, ...
        getDataIndexFromAngle(p,ang_i,ds_i), ds_i);
    if ~isempty(m)
        id{i} = m.ID;
    end
end

if nargout > 0
    ret = id;
end
