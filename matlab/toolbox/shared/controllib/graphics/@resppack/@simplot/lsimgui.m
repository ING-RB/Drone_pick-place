function state = lsimgui(h, mode)
%LIMGUI Opens lsim GUI for the @simplot
%
% LSIMGUI(@SIMPLOT,MODE) Opens lsim GUI for the handle @SIMPLOT
% with MODE determining which tab is initially selected
%
%   See also LSIM, INITIAL.

%  Copyright 1986-2020 The MathWorks, Inc.

if isempty(h.Responses)
   msgbox(getString(message('Controllib:gui:LsimSystemRequired')), ...
      getString(message('Controllib:gui:strLinearSimulationTool')),'modal');
   state = [];
   return
end
LSIM = strcmp(h.Tag,'lsim');

if isempty(h.InputDialog) || ~isvalid(h.InputDialog) % No lsim GUI has been created
   % Set waiting cursor
   set(get(get(h,'axesgrid'),'parent'),'Pointer','watch');

   % Create data
   data = lsimgui.internal.LinearSimulationData;
   if LSIM
      % Get time and signal parameters if input is defined
      if ~isempty(h.Input)
         % Time
         if ~isempty(h.Input.Data(1).Time)
            data.TimeVector = h.Input.Data(1).Time;
         end
         % Signal
         if ~isempty(h.Input.Data(1).Amplitude)
            inputdata = get(h.Input.Data,{'Amplitude'});
            n = length(inputdata);
            inputSignals = repmat(lsimgui.utils.internal.createEmptySignal(),1,n);
            for k=1:n
               if ~isempty(inputdata{k})
                  inputSignals(k) = lsimgui.utils.internal.createEmptySignal();
                  inputSignals(k).Value = inputdata{k};
                  inputSignals(k).Source = 'ini';
                  inputSignals(k).Interval = [1 length(inputdata{k})];
                  inputSignals(k).Column = k;
                  inputSignals(k).Name = 'default';
                  inputSignals(k).Size = [size(inputdata{k},1) length(inputdata)];
               end
            end
            updateInputSignals(data,inputSignals,1:n);
         end
      end
   else

   end
   % Get sources
   sources = get(h.Responses,'datasrc');
   if ~iscell(sources)
      sources = {sources};
   end
   % Define number of inputs and channel names
   data.NumberOfInputs = length(h.Input.ChannelName);
   data.ChannelNames = h.Input.ChannelName;
   % Get system specifications
   nSystems = length(h.Responses);
   systemSpec = repmat(lsimgui.utils.internal.createEmptySystemSpecification(),1,nSystems);
   for k = 1:length(h.Responses)
      resp = h.Responses(k);
      source = resp.DataSrc;
      sys = source.Model(:,:,1);
      % Name
      systemSpec(k).Name = resp.Name;
      % Class
      systemSpec(k).Type = class(sys);
      % States
      if strcmp(systemSpec(k).Type,'ss')
         nStates = order(sys);
         if isscalar(nStates)
            % StateName
            stateNames = sys.StateName;
            defaultStateNames = cellstr([repmat('state',nStates,1) num2str((1:nStates)')]);
            emptyIdx = find(strcmp(stateNames,''));
            stateNames(emptyIdx) = defaultStateNames(emptyIdx);
            systemSpec(k).StateName = stateNames;
            % Initial State Values
            if LSIM
               initialStates = resp.Context.IC;
            else
               initialStates = resp.Context.Config.InitialState;
            end
            if isempty(initialStates) || ~isequal(length(initialStates),nStates)
               initialStates = zeros(nStates,1);
            end
            systemSpec(k).InitialStates = initialStates;
         end
      end
   end
   data.Systems = systemSpec;

   h.InputDialog = lsimgui.internal.LinearSimulationTool(data);
   h.InputDialog.Type = h.Tag;
   show(h.InputDialog);
   %     pack(h.InputDialog);
   L = [handle.listener(h,'ObjectBeingDestroyed',@(es,ed) localDelete(h));...
      handle.listener(h.Responses,'ObjectBeingDestroyed', @(es,ed) localDelete(h));...
      handle.listener([sources{:}],'SourceChanged',@(es,ed) localDelete(h));...
      handle.listener(h,findprop(h,'Responses'),'PropertyPostSet',@(es,ed) localDelete(h))];
   registerUIListeners(h.InputDialog,L,'DeleteListeners');

   L = handle.listener(h,findprop(h,'Visible'),'PropertyPostSet', @(es,ed) localVisibleChange(h));
   registerUIListeners(h.InputDialog,L,'VisibleChangedListeners');

   addlistener(h.InputDialog,'SimulateButtonPushed',@(es,ed) localSimulate(h,es,ed));
   set(get(get(h,'Axesgrid'),'parent'),'Pointer','arrow');

else % Reset main panel - an lsim gui already exists
   show(h.InputDialog);
end
selectTab(h.InputDialog,mode);
end

%-------------------- Local Functions ---------------------------

function localVisibleChange(h)
if strcmp(string(h.Visible),"on")
   show(h.InputDialog);
else
   hide(h.InputDialog);
end
end

function localSimulate(h,es,ed)
% Updates the simulation based on the current GUI configuration
lsimFigure = getWidget(es);
% Process input vector for lsim plots
LSIM = strcmp(h.Tag,'lsim');
if LSIM
   % Update the @simplot
   minlength = es.Data.SimulationSamples;
   if ~isempty(minlength) && minlength > 0 && ...
         ~isempty(es.Data.Interval) && es.Data.Interval>0

      % Time vector
      T = (0:(minlength-1))*es.Data.Interval+es.Data.StartTime;

      numinputs = length(es.Data.InputSignals);

      % Create input matrix as a cell array
      X = cell(1,numinputs);
      for k=1:numinputs
         rawdata = es.Data.InputSignals(k).Value;
         if ~isempty(rawdata)
            X{k} = rawdata(es.Data.InputSignals(k).Interval(1):es.Data.InputSignals(k).Interval(2));
         else
            X{k} = [];
         end
      end

      % How many responses have enough inputs?
      numSimulations = 0;
      inputsUsed = false(numinputs,1);
      for k=1:length(h.Responses)
         if ~isempty(h.Responses(k).DataSrc) && all(ismember(h.Responses(k).Context.InputIndex,find(~cellfun('isempty',X))))
            numSimulations = numSimulations+1;
            inputsUsed(h.Responses(k).Context.InputIndex) = true;
         end
      end

      minlength = min(minlength, min(cellfun('length',X(inputsUsed))));
      if minlength<=1
         uiconfirm(lsimFigure,...
            getString(message('Controllib:gui:LsimMinSamples')),...
            getString(message('Controllib:gui:strLinearSimulationTool')),...
            'Icon','error');
         return
      end

      % Warn or error if there are insufficient inputs
      if numSimulations==0
         uiconfirm(lsimFigure,...
            getString(message('Controllib:gui:LsimIncompleteInputSet')),...
            getString(message('Controllib:gui:strLinearSimulationTool')),...
            'Icon','error');
         return
      elseif numSimulations<length(h.Responses)
         uiconfirm(lsimFigure,...
            getString(message('Controllib:gui:LsimOutputsGeneratedWarning',numSimulations, length(h.Responses))),...
            getString(message('Controllib:gui:strLinearSimulationTool')),...
            'Icon','warning');
      end

      % Update Input @waveform with the specified inputs
      for k=1:numinputs
         if inputsUsed(k)
            h.Input.Data(k).Time = T;
            h.Input.Data(k).Focus = [T(1) T(end)];
            h.Input.Data(k).Amplitude = X{k}(1:minlength);
         else
            h.Input.Data(k).Time = [];
            h.Input.Data(k).Focus = [];
            h.Input.Data(k).Amplitude = [];
         end
      end
      h.Input.Interpolation =  es.Data.Interpolation;
      inputVisible = h.Input.Visible;
   else
      uiconfirm(lsimFigure,...
         getString(message('Controllib:gui:LsimInvalidTimeInterval')), ...
         getString(message('Controllib:gui:strLinearSimulationTool')),...
         'Icon','error');
      return
   end
end

% Process initial states for lsim and initial plots
for k=1:length(h.Responses)
   if isStateSpace(h.Responses(k).datasrc.model)
      idx = find(strcmp({h.InputDialog.Data.Systems.Name},h.Responses(k).Name));
      x0 = h.InputDialog.Data.Systems(idx).InitialStates;
      if LSIM
         h.Responses(k).Context.IC = x0;
      else
         h.Responses(k).Context.Config.InitialState = x0;
      end
   end
end

% Clear data so that draw will refresh
for k=1:length(h.Responses)
   h.Responses(k).Data.clear;
end

% Refresh input waveforms
h.Input.refresh;

% Draw the plot
if isvisible(h)
   h.draw;
else
   h.Visible = 'on'; %ltiviewer opens the lsimgui with an invisible @simplot
end

% Write back the previous @simplot input visibility for lsim plots
if strcmp(h.Tag,'lsim')
   h.Input.Visible = inputVisible;
end

% Transfer the focus to the @simplot
figure(double(h.axesgrid.parent));
end



function localDelete(h)
% Resets the lsim GUI after hiding it
if ~isempty(h.InputDialog) && isvalid(h.InputDialog)
   delete(h.InputDialog);
   h.InputDialog = [];
end
end


