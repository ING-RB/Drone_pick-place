classdef (TruncatedProperties, CaseInsensitiveProperties) ...
      HSVOptions < plotopts.RespPlotOptions
   %HSVPLOTOPTIONS class
   
   %  Copyright 1986-2021 The MathWorks, Inc.
   
   properties
      YScale = 'log';
   end
   
   properties (Hidden)
      AbsTol = 0;
      RelTol = 1e-8;
      Offset = 1e-8;
      FreqIntervals = [];
      TimeIntervals = [];
   end
   
   methods
      % ------------------------------------------------------------------------%
      % Constructor
      % ------------------------------------------------------------------------%
      
      function this = HSVOptions(varargin)
         
         varargin = controllib.internal.util.hString2Char(varargin); % convert string in varargin to char array
         
         if any(strcmpi(varargin,'cstprefs'))
            mapCSTPrefs(this);
         end
         
         this.Title.String = getString(message('Controllib:plots:strHSVTitle'));
         this.XLabel.String = getString(message('Controllib:plots:strState'));
         this.YLabel.String = getString(message('Controllib:plots:strStateEnergy'));
         this.Grid = 'on';  % on by default
         
      end
      
      % ------------------------------------------------------------------------%
      % Purpose:  Error handling of setting YScale property
      % ------------------------------------------------------------------------%
      function set.YScale(this, ProposedValue)
         if iscell(ProposedValue)
            ProposedValue = ProposedValue{1};
         end
         if ~any(strcmp(ProposedValue,{'linear','log'}))
            error(message('Controllib:plots:ScaleProperty1','YScale'))
         end
         this.YScale = ProposedValue;
      end
            
   end
end

