function schema
%SCHEMA  Defines properties specific to @marginsource class 
% (LTI source for TuningGoal.Margins and diskmarginplot)

%   Copyright 1986-2020 The MathWorks, Inc.
pkg = findpackage('resppack');
c = schema.class(pkg, 'marginsource', findclass(pkg, 'ltisource'));
schema.prop(c, 'Skew','MATLAB array'); % sigma
