function schema
% Properties of IOWAVE class.

%  Copyright 2011-2015 The MathWorks, Inc.

% Register class 
ppk = findpackage('wavepack');
pk = findpackage('iodatapack');
c = schema.class(pk,'iowave',findclass(ppk,'waveform'));
schema.prop(c, 'InputIndex','MATLAB array');   % Input channels
schema.prop(c, 'OutputIndex','MATLAB array');  % Output channels
%{
p = schema.prop(c, 'ExpNo','MATLAB array');    % Row Vector of indices 
                                               % to be plotted (multiexp
                                               % iddata use)
p.FactoryValue = 1;
%}