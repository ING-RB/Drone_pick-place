function applyOptions(this, Options)
% APPLYOPTIONS  Synchronizes Response and Characteristics options

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2007 The MathWorks, Inc.

% Response curve preferences
applyOptions(this.Data, Options)
applyOptions(this.View, Options)

% Characteristics preferences
for ch = this.Characteristics'  % @wavechar
  applyOptions(ch.Data, Options)
  applyOptions(ch.View, Options)
end