function addtip(this,tipfcn,info)
%ADDTIP  Adds a buttondownfcn to each curve in each view object

%  Author(s): John Glass
%  Copyright 1986-2004 The MathWorks, Inc.

% MarginType 1 = GainMargin, 2 = PhaseMargin
info.MarginType = 1;
this.installtip(this.MagPoints,tipfcn,info)
set(this.MagPoints,'Tag','CharPoint')

info.MarginType = 2;
this.installtip(this.PhasePoints,tipfcn,info)
set(this.PhasePoints,'Tag','CharPoint')
