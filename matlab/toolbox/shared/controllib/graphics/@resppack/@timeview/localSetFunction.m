function valueStored = localSetFunction(this, ProposedValue, Prop)
% Setfunctions

% Copyright 2015 The MathWorks, Inc.

switch Prop
    case 'Style'
        valueStored = LocalSetStyle(this,ProposedValue);  
end


%----------------------LOCAL SET FUCTIONS---------------------------------%

function NewValue = LocalSetStyle(this,NewValue)
Curves = this.Curves;
if strcmpi(NewValue, 'stem')
    for ct = 1:length(Curves)
        this.StemLines(ct).Visible = Curves(ct).Visible;
        set(this.Curves,'LineStyle','none','Marker','o');
    end
else
    for ct = 1:length(Curves)
        this.StemLines(ct).Visible = 'off';
    end
end
