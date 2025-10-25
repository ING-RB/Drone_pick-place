function addPeripheralAxes(this, Location)
% If no location was passed in, create axes at location 'Left',
% by default

%   Copyright 2015-2020 The MathWorks, Inc.

if nargin == 1
    Location = 'Left';
end

% Get the peripheral axes at specified location
PAx = getPeripheralAxesGrid(this, Location);

% Create a grid of 1-by-nC size
if isempty(PAx)
    [nR,nC] = size(this);
    % If axes grid does not exist
    switch Location
        case {'Top', 'Bottom'}
            % Create axes grid of appropriate size
            PAx = controllib.ui.plotmatrix.internal.ManageAxesGrid(1,nC,'BackgroundAxes',false,'Parent',this.Parent);
            % XTick marks are not needed
            set(PAx.getAxes, 'XTickLabel', []);
            
            
            % ~The XAxes shares limits with the core grid~
            
            % Set the XLimits to be the same as core
            setXLim_(PAx, this.XLim(1,1:nC));
            
            % Set the XScale to be same as core
            setXScale_(PAx, this.XScale(1,1:nC));
            
            % Set the grid to be same as core
            setGrid_(PAx, this.Grid);
            
            % Set x-tick marks to outer edges if location is
            % Top
            if strcmpi(Location, 'Top')
                a = PAx.getAxes;
                for ct = 1:length(a)
                    a(ct).XAxisLocation ='Top';
                end
                
                % Set title to north peripheral axes
                PAx.Title = this.AxesGrid.Title;
                this.AxesGrid.Title = '';
            end
            
            % ~Set up listeners to core~
            L = cell(0,1);
            % Change size of peripheral grid when number of columns
            % of core changes
            L = [L; {addlistener(this, 'SizeChanged', @(es,ed)resizePeripheralAxes(PAx, 1, size(this,2), Location))}];
            
            % Changing the XLim of core changes XLim of peripheral
            % grid
            %                         L = [L; {addlistener(this, 'XLimChanged',  @(es,ed)setXLim_(PAx, this.XLim(1,:)))}];
            
            L = [L; {handle.listener(this.AxesGrid, 'ViewChanged',  @(es,ed)setXLim_(PAx, this.XLim(1,:)))}];
            
            % Changing the Scale of core changes scale of
            % peripheral grid
            
            L = [L; {addlistener(this, 'XScaleChanged', @(es,ed)setXScale_(PAx, this.XScale(1,:)))}];
            
            % Changing the grid of core changes the grid of
            % peripheral grid
            L = [L; {addlistener(this, 'GridChanged', @(es,ed)setGrid_(PAx, this.Grid))}];
            
            % Changing the visibility of the core changes the
            % visibility of the peripheral grid
            L = [L; {addlistener(this, 'VisibilityChanged',  @(es,ed)setAxesVisibility_(PAx, this.AxesGrid.ColumnVisible))}];
            PAxGrid = controllib.ui.plotmatrix.internal.ManagePeripheralAxesGrid_TB(PAx, PAx.AxesGrid);
            
        case {'Right', 'Left'}
            % Create axes grid of appropriate size
            PAx = controllib.ui.plotmatrix.internal.ManageAxesGrid(nR,1,'BackgroundAxes',false,'Parent',this.Parent);
            PAx.Parent = this.Parent;
            % YTicks are shown by the core axes grid.
            set(PAx.getAxes, 'YTickLabel', []);
            
            % Set the YLimits to be the same as core
            setYLim_(PAx, this.YLim(1:nR,1));
            
            % Set the YScale to be same as core
            setYScale_(PAx, this.YScale(1:nR,1));
            
            setGrid_(PAx, this.Grid);
            
            % Set y-tick marks to outer edges if location is right
            if strcmpi(Location, 'Right')
                a = PAx.getAxes;
                for ct = 1:length(a)
                    a(ct).YAxisLocation = 'Right';
                end
            end
            
            % ~Set up listeners to core~
            L = cell(0,1);
            % Change size of peripheral grid when number of columns
            % of core changes
            L = [L; {addlistener(this, 'SizeChanged', @(es,ed)resizePeripheralAxes(PAx, size(this,1), 1, Location))}];
            
            % Changing the XLim of core changes XLim of peripheral
            % grid
            %                         L = [L; {addlistener(this, 'YLimChanged', @(es,ed)setYLim_(PAx, this.YLim(:,1)))}];
            L = [L; {handle.listener(this.AxesGrid, 'ViewChanged',  @(es,ed)setYLim_(PAx, this.YLim(:,1)))}];
            
            % Changing the Scale of core changes scale of
            % peripheral grid
            L = [L; {addlistener(this, 'YScaleChanged', @(es,ed)setYScale_(PAx, this.YScale(:,1)))}];
            
            % Changing the grid of core changes the grid of
            % peripheral grid
            L = [L; {addlistener(this, 'GridChanged', @(es,ed)setGrid_(PAx, this.Grid))}];
            
            % Changing the visibility of the core changes the
            % visibility of the peripheral grid
            L = [L; {addlistener(this, 'VisibilityChanged',  @(es,ed)setAxesVisibility_(PAx, this.AxesGrid.RowVisible))}];
            PAxGrid = controllib.ui.plotmatrix.internal.ManagePeripheralAxesGrid_LR(PAx, PAx.AxesGrid);
        otherwise
            error(message('Controllib:general:UnexpectedError', ...
                'Invalid location specified. Location must be Top, Bottom, Left or Right '));
            
    end
    
    P = struct('AxesGrid', PAxGrid, 'Location', Location, 'Listeners', {L});
    
    setPeripheralAxes(this, P);
    
    layout(this);
end

end
