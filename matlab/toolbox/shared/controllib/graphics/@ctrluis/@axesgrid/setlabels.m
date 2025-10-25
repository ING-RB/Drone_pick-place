function setlabels(this,varargin)
%SETLABELS  Updates visibility, style, and contents of HG labels.

%   Author: P. Gahinet
%   Copyright 1986-2013 The MathWorks, Inc.

% Outer label visibility
backax = this.BackgroundAxes;
set([backax.Title;backax.XLabel;backax.YLabel],'Visible',this.Visible);

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
        if ~isempty([VisAxes(ct).Title_IS,VisAxes(ct).XAxis.Label_IS,VisAxes(ct).YAxis.Label_IS])
            set([VisAxes(ct).Title,VisAxes(ct).XAxis.Label_I,VisAxes(ct).YAxis.Label_I],'String','','HitTest','off');
        end
    end
    
    % Tick labels on borders
    if strcmp(this.YNormalization,'off')
        set(VisAxes(:,1),'YTickLabelMode','auto')
    end
    set(VisAxes(nr,:),'XTickLabelMode','auto')
    
    % MIMO CASE
    % RowLabel: 'To: out(n)'
    % YLabel:   'Magnitude (dB)'
    
    % SISO CASE
    % RowLabel: 'Magnitude (dB)'
    % YLabel:   ''
    
    % Row labels
    if any(strcmp(this.AxesGrouping,{'none','column'})) ||...
            (any(strcmp(this.AxesGrouping, {'all','row'})) && prod(this.Size(1:2))==1)
        % Check: MIMO with AxesGrouping 'none'/'column'
        %  (or)  SISO with AxesGrouping 'all'/'row'
        
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
        
        if strcmpi(LabelMap.RowLabelStyle.Location,'left')
            for ct=1:nr
                set(VisAxes(ct,1).YAxis(1).Label_I,'String',LabelMap.RowLabel{indrow(ct)},RowLabelStyle,...
                    'HitTest','off');
                % Use semantic color variables to set label color
                controllib.plot.internal.utils.setColorProperty(...
                    VisAxes(ct,1).YAxis(1).Label_I,"Color",rowLabelColor);
            end
        elseif strcmpi(LabelMap.RowLabelStyle.Location,'top')
            for ct=1:nr
                set(VisAxes(ct,1).Title,'String',LabelMap.RowLabel{indrow(ct)},RowLabelStyle,'HitTest','off')
                % Use semantic color variables to set label color
                controllib.plot.internal.utils.setColorProperty(...
                    VisAxes(ct,1).Title,"Color",rowLabelColor);
            end
        end
    end
    
    % Column labels
    if any(strcmp(this.AxesGrouping,{'none','row'}))
        % Get ColumnLabelStyle and remove Color field (recommended to not set Color manually)
        ColumnLabelStyle = struct(LabelMap.ColumnLabelStyle);
        ColumnLabelStyle = rmfield(ColumnLabelStyle,'Color');
        if strcmp(LabelMap.ColumnLabelStyle.ColorMode,"auto")
            columnLabelColor = "--mw-color-secondary";
        else
            columnLabelColor = LabelMap.ColumnLabelStyle.Color;
        end
        
        if strcmpi(LabelMap.ColumnLabelStyle.Location,'top')
            for ct=1:nc,
                set(VisAxes(1,ct).Title,'String',LabelMap.ColumnLabel{indcol(ct)},ColumnLabelStyle,...
                    'HitTest','off');
                % Use semantic color variables to set label color
                controllib.plot.internal.utils.setColorProperty(...
                    VisAxes(1,ct).Title,"Color",columnLabelColor);
            end
        else
            for ct=1:nc,
                set(VisAxes(nr,ct).XAxis(1).Label_I,'String',LabelMap.ColumnLabel{indcol(ct)},ColumnLabelStyle,...
                    'HitTest','off');
                % Use semantic color variables to set label color
                controllib.plot.internal.utils.setColorProperty(...
                    VisAxes(nr,ct).XAxis(1).Label_I,"Color",columnLabelColor);
            end
        end
    end
    
    % Adjust position of background axes labels
    % RE: Still needed for empty axis (no data -> no LimitChanged event)
    labelpos(this)
end
