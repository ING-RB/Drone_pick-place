function addconstr(this, Constr, varargin)  
% ADDCONSTR  method to add a requirement to a pole/zero plot
%

% Author(s): A. Stothert 20-Oct-2010
% Copyright 2010 The MathWorks, Inc.

if nargin > 2
   doInit = ~strcmp(varargin{1},'NoInitialization');
else
   doInit = true;
end

if doInit
   % REVISIT: should call grapheditor::addconstr to perform generic init
   Axes = this.AxesGrid;
   
   % Generic init (includes generic interface editor/constraint)
   initconstr(this,Constr)
   
   % Add related listeners
   L = [...
       handle.listener(this,this.findprop('TimeUnits'), 'PropertyPostSet', {@LocalSetUnits,Constr,'time'}); ...
       handle.listener(this,this.findprop('FrequencyUnits'), 'PropertyPostSet', {@LocalSetUnits,Constr,'frequency'})];
   Constr.addlisteners(L);
   
   % Activate (initializes graphics and targets constr. editor)
   Constr.Activated = 1;
   
   % Update limits
   Axes.send('ViewChanged')
end

%Add to list of requirements on the plot
this.Requirements = vertcat(this.Requirements,Constr);
end

function LocalSetUnits(~,eventData,Constr,whichUnit)
% Syncs constraint props with related Editor props

switch whichUnit
    case 'time'
        newUnits = eventData.NewValue;
        if isa(Constr,'plotconstr.pzfrequency')
            Constr.setDisplayUnits('yunits',newUnits)
            Constr.TextEditor.setDisplayUnits('yunits',newUnits)
        else
            Constr.setDisplayUnits('xunits',newUnits)
            Constr.TextEditor.setDisplayUnits('xunits',newUnits)
        end
    case 'frequency'
        newUnits = eventData.NewValue;
        if isa(Constr,'plotconstr.pzfrequency')
            Constr.setDisplayUnits('xunits',newUnits)
            Constr.TextEditor.setDisplayUnits('xunits',newUnits)
        end
end

% Update constraint display (and notify observers)
update(Constr)
end
