function setAutoTimeUnits(this)
%  setAutoTimeUnits  Sets Time Units to inherit from first system
%

%  Copyright 1986-2010 The MathWorks, Inc.

if isempty(this.Responses)
    % Set up listener when system is added
    h = handle.listener(this,this.findprop('Responses'),'PropertyPostSet',{@LocalUpdate this});
    this.AutoUnitsListener=h;
else
    LocalSetTimeUnits(this)
end
end


function LocalSetTimeUnits(this)
% Get units from first system and set the Time Units
r = this.Responses(1);
try
    if isempty(r.DataSrc)
        this.AxesGrid.XUnits = r.Data.TimeUnits;
    else
        this.AxesGrid.XUnits = r.DataSrc.getTimeUnits;
    end
end
end

function LocalUpdate(~,~,this)
% Get units from first system and set the Time Units
if ~isempty(this.Responses)
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