function tT = addprop(tT, varargin)
%ADDPROP Declare custom properties for a table.
%   T = ADDPROP(T,PROPERTYNAMES,PROPERTYTYPES)
%
%   See also TABULAR/ADDPROP.

%   Copyright 2018 The MathWorks, Inc.

tall.checkIsTall(mfilename, 1, tT);
tall.checkNotTall(mfilename, 1, varargin{:});
tT = tall.validateType(tT, mfilename, {'table', 'timetable'}, 1);

fh = @(t) addprop(t, varargin{:});
tall.validateSyntax(fh, {tT}, ...
    'DefaultType', 'double', ...
    'NumOutputs', nargout);

adaptor = tT.Adaptor;
tT = elementfun(fh, tT);
tT.Adaptor = joinBySample(fh, false, adaptor);
