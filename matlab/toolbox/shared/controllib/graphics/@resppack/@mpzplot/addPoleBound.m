function r = addPoleBound(this,MinDecay,MinDamping,MaxFrequency,Ts)
%addPoleBound  Adds a bound for spectral radius and spectral abscissa
%
% A spectral abscissa bound Re(s)<-MinDecay
% A spectral radius bound |s|<MaxFrequency
% A damping ratio bound Re(s)<-MinDamping*|s|
%
% MinDecay and MaxFrequency are defined in seconds^-1

%   Copyright 1986-2013 The MathWorks, Inc.

r = this.addresponse('resppack.SpectralBoundView');
r.Name = 'Pole Bounds';
r.setstyle('color',[250   250   150]/255)
r.Data.Ts = Ts;
r.Data.MinDecay = MinDecay;
r.Data.MinDamping = MinDamping;
r.Data.MaxFrequency = MaxFrequency;
r.draw
