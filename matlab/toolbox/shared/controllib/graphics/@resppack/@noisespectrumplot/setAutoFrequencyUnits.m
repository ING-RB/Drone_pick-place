function setAutoFrequencyUnits(this)
%  setAutoFrequencyUnits  Sets Frequency Units to inherit from first system
%

%  Copyright 1986-2010 The MathWorks, Inc.

if isempty(this.Responses)
   % Set up listener when system is added
   h = handle.listener(this,this.findprop('Responses'),'PropertyPostSet',{@LocalUpdate this});
   this.AutoUnitsListener=h;
else
   LocalSetFrequencyUnits(this)
end
end


function LocalSetFrequencyUnits(this)
% Get units from first system and set the Time Units
r = this.Responses(1);
try
   if isempty(r.DataSrc)
      this.AxesGrid.XUnits = {r.Data.FreqUnits};
   else
      this.AxesGrid.XUnits = {r.DataSrc.getFrequencyUnits};
   end
end
end

function LocalUpdate(~,~,this)
% Get units from first system and set the Time Units
if ~isempty(this.Responses)
   DataExceptionWarningState = this.DataExceptionWarning;
   this.DataExceptionWarning='off'; % Prevent warnings when datafcn has not been set
   LocalSetFrequencyUnits(this)
   LocalDeleteListeners([],[],this)
   this.DataExceptionWarning=DataExceptionWarningState;
end
end

function LocalDeleteListeners(~,~,this)
delete(this.AutoUnitsListener)
end
