function schema
% Defines properties for @axes class (single axes)

%   Copyright 1986-2021 The MathWorks, Inc.

% Register class 
pk = findpackage('ctrluis');
c = schema.class(pk,'axes',findclass(pk,'axesgroup'));

% Properties
p = schema.prop(c,'LimitStack','MATLAB array');    % Limit stack
p.FactoryValue = struct('Limits',zeros(0,4),'Index',0);

schema.prop(c,'XLimitsContainer','MATLAB array');
schema.prop(c,'YLimitsContainer','MATLAB array');
