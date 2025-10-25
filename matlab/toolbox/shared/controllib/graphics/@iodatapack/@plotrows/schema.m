function schema
% Class representing a column of row vectors of axes.

%   Copyright 2013-2015 The MathWorks, Inc.

% Register class 
ppk = findpackage('ctrluis');
pk = findpackage('iodatapack');
c = schema.class(pk,'plotrows', findclass(ppk,'plotarray'));
schema.prop(c,'RowLen','MATLAB array'); % e.g.: [ny nu]


% Orientation:
% one of: '2row', '2col', '1row', '1col'
% default: '2row'
p = schema.prop(c,'Orientation','ustring'); 
p.FactoryValue = '2row';
