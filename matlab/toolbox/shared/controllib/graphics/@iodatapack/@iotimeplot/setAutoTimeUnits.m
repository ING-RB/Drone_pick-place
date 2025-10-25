function setAutoTimeUnits(this)
%  setAutoTimeUnits  Sets Time Units to inherit from first system

%  Copyright 2013 The MathWorks, Inc.
if isempty(this.Waves)
   % Set up listener when system is added
   h = handle.listener(this,this.findprop('Waves'),'PropertyPostSet',{@LocalUpdate this});
   this.AutoUnitsListener = h;
else
   LocalSetTimeUnits(this)
end
end

function LocalSetTimeUnits(this)
% Get units from first signal of the first system and set them to axes grid
% units
r = this.Waves(1);
try
   this.AxesGrid.XUnits = r.DataSrc.getTimeUnits;
end
end

function LocalUpdate(~,~,this)
% Get units from first system and set the Time Units
if ~isempty(this.Waves)
   DataExceptionWarningState = this.DataExceptionWarning;
   this.DataExceptionWarning= 'off'; % Prevent warnings when datafcn has not been set
   LocalSetTimeUnits(this)
   setlabels(this.AxesGrid)
   LocalDeleteListeners([],[],this)
   this.DataExceptionWarning = DataExceptionWarningState;
end
end

function LocalDeleteListeners(~,~,this)
delete(this.AutoUnitsListener)
end