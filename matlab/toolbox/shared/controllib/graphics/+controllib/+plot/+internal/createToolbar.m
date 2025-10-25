function createToolbar(axes,buttonList)
%CREATETOOLBAR Creates a graphical bases AxesToolbar for the given axes
% axes is required, buttonList is an optional parameter that allows the
% caller to specify which buttons appear in the toolbar
%
% createToolbar(AxesHandle)
% createToolbar(AxesHandle, ButtonList)
%    where ButtonList is a cell array of one or more of the following:
%         'ZoomIn', 'ZoomOut', 'Pan', 'Legend'
%    For example:
%       plot(1:10)
%       % Only show zoom and pan
%       controllib.plot.internal.createToolbar(gca,{'ZoomIn';'Pan'})


% Author(s): T. Roderick
% Copyright 2015-2022 The MathWorks, Inc.
narginchk(1,2)

DefaultList = {'Legend';'Pan';'ZoomOut';'ZoomIn'};
if nargin == 1
    buttonList = DefaultList;
end

if isempty(axes)
    %If no inputs are passed to the constructor, or, if anything other
    %than an axes handle is passed, produce an error.
    error(message('Controllib:gui:ToolbarErrInput'));
end

% The axes argument could be an array of axes
for idx = 1:numel(axes)
    ax = axes(idx);
    
    if ~ishghandle(ax)
        %If no inputs are passed to the constructor, or, if anything other
        %than an axes handle is passed, produce an error.
        error(message('Controllib:gui:ToolbarErrInput'));
    else
        
        % Add the buttons to the AxesToolbar
        tb = axtoolbar(ax);
        tb.Visible = 'on';
        
        ziBtn = [];
        zoBtn = [];
        panBtn = [];
        
        iconsFolder = toolboxdir(['shared', filesep, 'controllib', ...
                    filesep, 'graphics', filesep, '+controllib', filesep, ...
                    'resources']);
        
        for i=1:length(buttonList)
            switch buttonList{i}
                case 'ZoomIn'
                    ziBtn = matlab.graphics.controls.ToolbarController.createToolbarButton('zoomin', ax);                       
                case 'ZoomOut'
                    zoBtn = matlab.graphics.controls.ToolbarController.createToolbarButton('zoomout', ax);                      
                case 'Pan'
                    panBtn = matlab.graphics.controls.ToolbarController.createToolbarButton('pan', ax);                    
                case 'Legend'
                    legendBtn = axtoolbarbtn(tb, 'state');
                    legendBtn.Tooltip = getString(message('Controllib:gui:PlotTabLegendLegend'));
                    legendBtn.Icon = fullfile(iconsFolder, 'legend_normal_16.png');
                    legendBtn.ValueChangedFcn = @(e, d) localToggleLegend(e,d);
                    legendBtn.Tag = 'legend';
            end
        end
        
        if ~isempty(zoBtn)
            zoBtn.Parent = tb;
        end
        
        if ~isempty(ziBtn)
            ziBtn.Parent = tb;
        end
        
        if ~isempty(panBtn)
            panBtn.Parent = tb;
        end
        
        set(tb.Children, 'Visible', 'on');
    end
end
end

function localToggleLegend(source, eventData)
if strcmpi(source.Value, 'on')
    legend(eventData.Axes, 'show');
else
    legend(eventData.Axes, 'off');
end
end
