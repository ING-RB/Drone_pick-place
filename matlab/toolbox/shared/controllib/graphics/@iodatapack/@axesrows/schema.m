function schema
% Class representing rows of I/O axes.

% Copyright 2013-2018 The MathWorks, Inc.

% Register class 
ppk = findpackage('ctrluis');
pk = findpackage('iodatapack');
c = schema.class(pk,'axesrows',findclass(ppk,'axesgrid'));

% Used only to decide how to split axes rows into two groups - first group
% of output axes and the second for input axes. Not applicable when number
% of columns is greater than 1. 
% two element row vector
schema.prop(c,'RowLen','MATLAB array'); % e.g.: [ny nu]

p = schema.prop(c,'Orientation','ustring'); 
p.FactoryValue = '2row';
p.SetFunction = @localSetOrientation;
p.Getfunction = @localGetOrientation;

% to distinguish between predmaint use ("signals") and ident use
% ("outputs"); used in setlabels
p = schema.prop(c,'IsPredmaint','MATLAB array'); % e.g.: [ny nu]
p.FactoryValue = false;

%--------------------------------------------------------------------------
function Value = localSetOrientation(h, Value)
%Set the IO data plot orientation.
% Value must be one of: '2row', '2col', '1row', '1col'.
%
% For IO data plot, the default is '2row'.

Orientation = lower(Value);
assert(ismember(Orientation,{'2row','2col','1row','1col'}),...
   'Incorrect value for Orientation specified (axesrows:schema).')

setOrientation(h,Orientation);

%--------------------------------------------------------------------------
function Value = localGetOrientation(h, varargin)
% Get visibility of main panel
Value = getOrientation(h);
