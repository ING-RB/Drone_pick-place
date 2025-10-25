function tT = rmprop(tT, varargin)
%ADDPROP Remove custom properties from a table.
%   T = RMPROP(T,PROPERTYNAMES)
%
%   See also TABULAR/RMPROP.

%   Copyright 2018-2023 The MathWorks, Inc.

tall.checkIsTall(mfilename, 1, tT);
tall.checkNotTall(mfilename, 1, varargin{:});
tT = tall.validateType(tT, mfilename, {'table', 'timetable'}, 1);

fh = @(t) rmprop(t, varargin{:});
tall.validateSyntax(fh, {tT}, ...
    'DefaultType', 'double', ...
    'NumOutputs', nargout);

adaptor = tT.Adaptor;
tT = elementfun(fh, tT);
tT.Adaptor = joinBySample(fh, false, adaptor);
