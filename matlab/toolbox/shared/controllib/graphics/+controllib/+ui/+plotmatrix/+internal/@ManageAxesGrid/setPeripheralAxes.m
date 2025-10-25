function setPeripheralAxes(this, P)
% setPeripheralAxes - Append the peripheralAxes property with
% newly created peripheral axes grid

%   Copyright 2015-2020 The MathWorks, Inc.

this.PeripheralAxes = [this.PeripheralAxes; P];
end
