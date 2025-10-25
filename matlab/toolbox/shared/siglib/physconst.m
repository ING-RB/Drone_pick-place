function y = physconst(param)
%physconst Physical constants of natural phenomena
%   C = physconst(Name) returns the physical constant C specified by Name.
%   The returned physical constant uses International System of Units (SI).
%   Name can be any entry from the following list:
%
%   Name               Description
%   ------------------------------
%   'LightSpeed'       The speed of light in vacuum (meter/second)
%   'Boltzmann'        Boltzmann constant (Joule/Kelvin)
%   'EarthRadius'      Radius of the earth (m)
%
%   % Example:
%   %   Obtain the speed of light in the free space.
%
%   v = physconst('LightSpeed')
%
%   See also phased, systemp, fspl.

%   Copyright 2006-2022 The MathWorks, Inc.

%#codegen 
%#ok<*EMCA

coder.extrinsic('earthRadius');

narginchk(1,1);

param = validatestring(param,{'lightspeed','boltzmann','earthradius'},'physconst','param');

if param(1) == 'l' 
    y = 299792458;
elseif param(1) == 'b'
    y = 1.380649e-23;
else
    y = coder.internal.const(earthRadius);
end

% [EOF]
