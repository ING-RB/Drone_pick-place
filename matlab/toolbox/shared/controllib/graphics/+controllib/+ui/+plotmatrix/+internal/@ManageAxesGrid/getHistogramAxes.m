function hndl = getHistogramAxes(this)
% This function adds a set of axes along the diagonals for the histograms.
% It links the XLim and XScale to the column. YLim and YScale are constant
% and cannot be modified.

%   Copyright 2015-2020 The MathWorks, Inc.

if isempty(this.HistogramAxes)
    [nR,nC] = size(this);
    
    if nR == nC
        % XVsX
        Ax = getaxes(this.AxesGrid);
        for ct = 1:nR
            % Create axes
            Position = get(Ax(ct,ct),'Position');
            hndl(ct) = handle(axes('Parent',this.AxesGrid.Parent,...
                'Box', 'on',...
                'Position', Position,...
                'Visible', get(Ax(ct,ct), 'Visible'), ...
                'XTick', [], ...
                'YTick', [], ...
                'units', 'normalized', ...
                'Tag', 'HistogramAxes'));
%             hndl(ct).XColor = 'w';
%             hndl(ct).YColor = 'w';
            % ~Set up listeners to histogram axes~
            L = addlistener(hndl(ct),'XLim','PostSet', @(es,ed)setXLimFromHistogram(this,ct));
            this.HistogramListeners.XLimListener(ct) = L;
        end
        % ~Set up listeners to core~
        L = cell(0,1);
        % Change size of peripheral grid when number of columns
        % of core changes
        L = [L; {addlistener(this, 'SizeChanged', @(es,ed)resizeHistogramAxes(this))}];
        
        % Changing the XLim of core changes XLim of peripheral
        % grid
        %                         L = [L; {addlistener(this, 'YLimChanged', @(es,ed)setYLim_(PAx, this.YLim(:,1)))}];
%         
        
        % Changing the Scale of core changes scale of
        % peripheral grid
        L = [L; {addlistener(this, 'XScaleChanged', @(es,ed)setHistogramXScale(this))}];
        
        
        % Changing the visibility of the core changes the
        % visibility of the peripheral grid
        L = [L; {addlistener(this, 'VisibilityChanged',  @(es,ed)setHistogramVisibility(this))}];

        
        % Changing the position of the core changes the position of the
        % histogram axes
        L2 = handle.listener(this.AxesGrid, 'FigureSizeChanged',  @(es,ed)setHistogramPosition(this,ed));
        
        this.HistogramAxes = hndl;
        this.HistogramListeners.L1 = L;
        this.HistogramListeners.L2 = [L2; handle.listener(this.AxesGrid, 'ViewChanged',  @(es,ed)setHistogramXLim(this))];
    else
        error(getString(message('Controllib:general:UnexpectedError', 'Number of rows and columns not equal')));
    end
else
    hndl = this.HistogramAxes;
end
end
