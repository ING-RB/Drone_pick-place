function setlabels(this,varargin)
%SETLABELS  Updates visibility, style, and contents of HG labels.

%   Copyright 2013-2019 The MathWorks, Inc.

% Outer label visibility
backax = this.BackgroundAxes;
set([backax.Title;backax.XLabel;backax.YLabel],'Visible',this.Visible);

sz = this.Size;
rlen = this.RowLen;

% Inner labels
if strcmp(this.Visible,'on')
   % Get map from @axesgrid properties to HG labels
   LabelMap = feval(this.LabelFcn{:});
   
   % Title, xlabel, ylabel contents and style
   titleStyle = struct(this.TitleStyle);
   if strcmp(this.TitleStyle.ColorMode,"auto")
       titleStyle = rmfield(titleStyle,'Color');
   end
   set(backax.Title,'String',this.Title,titleStyle);
   
   xlabelStyle = struct(LabelMap.XLabelStyle);
   if strcmp(LabelMap.XLabelStyle.ColorMode,"auto")
       xlabelStyle = rmfield(xlabelStyle,'Color');
   end
   set(backax.XAxis.Label_I,'String',LabelMap.XLabel,xlabelStyle);

   ylabelStyle = struct(LabelMap.YLabelStyle);
   if strcmp(LabelMap.YLabelStyle.ColorMode,"auto")
       ylabelStyle = rmfield(ylabelStyle,'Color');
   end
   set(backax.YAxis.Label_I,'String',LabelMap.YLabel,ylabelStyle);

   % Row and column visibility
   [VisAxes,indrow,indcol] = findvisible(this);
   [nr,nc] = size(VisAxes);
   if nr==0 || nc==0
      return
   end
   
   % Global reset
   set(VisAxes,'XTickLabel',[],'YTickLabel',[])
   for ct=1:nr*nc
      set([VisAxes(ct).Title,VisAxes(ct).XLabel,VisAxes(ct).YLabel],...
         'String','','HitTest','off')
   end
   
   % Tick labels on borders
   if strcmp(this.YNormalization,'off')
      set(VisAxes(:,1),'YTickLabelMode','auto')
   end
   if strcmp(this.AxesGrouping,'all') || strcmp(this.Orientation,'1col')
      n_ = nr; % axes grouped
   else
      n_ = 1:size(VisAxes,1); % all axes get labels by default
      RV = strcmpi(this.RowVisible,'on');
      yVis = RV(1:rlen(1),1,:); yVis = yVis(:);
      uVis = RV(rlen(1)+(1:rlen(2)),1,:); uVis = uVis(:);
      if sum(yVis)==sum(uVis)
         n_ = sum(yVis)+(1:sum(uVis));
      end
   end
   set(VisAxes(n_,:),'XTickLabelMode','auto')
   
   % Row labels
   RowLabel = LabelMap.RowLabel;
   RowVis = reshape(strcmp(this.RowVisible,'on'), sz([3 1]));
   % Get RowLabelStyle and remove Color field (recommended to not set Color manually)
   RowLabelStyle = struct(LabelMap.RowLabelStyle);
   RowLabelStyle = rmfield(RowLabelStyle,'Color');
   if strcmp(LabelMap.RowLabelStyle.ColorMode,"auto")
       if LabelMap.RowLabelStyle.Color == LabelMap.YLabelStyle.Color
           rowLabelColor = '--mw-graphics-borderColor-axes-primary';
       else
           rowLabelColor = '--mw-graphics-borderColor-axes-secondary';
       end
   else
       rowLabelColor = LabelMap.RowLabelStyle.Color;
   end
   
   if strcmp(this.AxesGrouping,'none')
      if sz(3)>1 % handle row labels for bode plots
         % Re: See iodatapack.iofrequencyplot.initialize where in single
         % channel case the row labels are themselves 'mag' and 'phase'.
         if prod(sz(1:2))==1
            % do nothing?
         else
            % at least two channels (e.g., SISO data)
            if ~any(RowVis(1,:))
               RowLabel(2:2:end) = RowLabel(1:2:end);
            else
               RowLabel(2:2:end) = {''};
            end
         end
      end
      if strcmpi(LabelMap.RowLabelStyle.Location,'left')
         for ct=1:nr
            set(VisAxes(ct,1).YLabel,'String',RowLabel{indrow(ct)},RowLabelStyle)
            % Use semantic color variables to set label color
            controllib.plot.internal.utils.setColorProperty(...
                VisAxes(ct,1).YLabel,"Color",rowLabelColor);
         end
      else
         for ct=1:nr
            set(VisAxes(ct,1).Title,'String',RowLabel{indrow(ct)},RowLabelStyle)
            % Use semantic color variables to set label color
            controllib.plot.internal.utils.setColorProperty(...
                VisAxes(ct,1).Title,"Color",rowLabelColor);
         end
      end
   elseif strcmp(this.AxesGrouping,'all')
      if this.IsPredmaint
         ystr = getString(message('predmaint:plot:strSignals'));
         if ~all(cellfun(@(x)isempty(x),this.RowLabel))
            TitleStr = join(this.RowLabel,', '); TitleStr = TitleStr{1};
         else
            TitleStr = '';
         end
      else
         ystr = getString(message('Controllib:plots:strOutputs'));
      end
      ustr = getString(message('Controllib:plots:strInputs'));
      
      RowLabel = [repmat({ystr},[1, rlen(1)]), repmat({ustr},[1, rlen(2)])];
      if sz(3)>1
         RowLabel = repmat(RowLabel,[sz(3),1]);
         if any(RowVis(1,:))
            RowLabel(2:2:end) = {''};
         end
      end
      
      if this.IsPredmaint
         set(VisAxes(1).Title,'String',TitleStr)
      end
      
      RowLabel = RowLabel(:); RowLabel = RowLabel(indrow);
     
      

      if strcmpi(LabelMap.RowLabelStyle.Location,'left')
         for ct = 1:size(VisAxes,1)
            set(VisAxes(ct,1).YLabel,'String',RowLabel{ct},RowLabelStyle)
            % Use semantic color variables to set label color
            controllib.plot.internal.utils.setColorProperty(...
                VisAxes(ct,1).YAxis(1).Label_I,"Color",rowLabelColor);
         end
      else
          if nc==1
              for ct = 1:size(VisAxes,1)
                  set(VisAxes(ct,1).Title,'String',RowLabel{ct},RowLabelStyle)
                  % Use semantic color variables to set label color
                  controllib.plot.internal.utils.setColorProperty(...
                      VisAxes(ct,1).Title,"Color",rowLabelColor);
              end
          else
              for ct = 1:size(VisAxes,1)
                  set(VisAxes(ct,1).Title,'String',['\Re(',RowLabel{ct},')'],RowLabelStyle)
                  set(VisAxes(ct,2).Title,'String',['\Im(',RowLabel{ct},')'],RowLabelStyle)
                  % Use semantic color variables to set label color
                  controllib.plot.internal.utils.setColorProperty(...
                      VisAxes(ct,1).Title,"Color",rowLabelColor);
                  % Use semantic color variables to set label color
                  controllib.plot.internal.utils.setColorProperty(...
                      VisAxes(ct,2).Title,"Color",rowLabelColor);
              end
          end
      end
   end
   
   % nc>1 condition was replaced with emptiness check on column label
   % strings in R2018b+.% Get ColumnLabelStyle and remove Color field (recommended to not set Color manually)
   ColumnLabelStyle = struct(LabelMap.ColumnLabelStyle);
   ColumnLabelStyle = rmfield(ColumnLabelStyle,'Color');
   if strcmpi(LabelMap.ColumnLabelStyle.Location,'top')
      for ct=1:nc
         if ~isempty(LabelMap.ColumnLabel{indcol(ct)})
            set(VisAxes(1,ct).Title,'String',LabelMap.ColumnLabel{indcol(ct)},...
               ColumnLabelStyle,'HitTest','off')
         end
      end
   else
      for ct=1:nc
         if ~isempty(LabelMap.ColumnLabel{indcol(ct)})
            set(VisAxes(nr,ct).XLabel,'String',LabelMap.ColumnLabel{indcol(ct)},...
               ColumnLabelStyle,'HitTest','off')
         end
      end
   end
   
   % Adjust position of background axes labels
   % RE: Still needed for empty axis (no data -> no LimitChanged event)
   labelpos(this)
end
