function [hh, ax] = pareto(varargin)
%

% Copyright 1984-2024 The MathWorks, Inc.

    % Parse possible Axes input
    [cax, args, nargs] = axescheck(varargin{:});
    
    if nargs == 0
        error(message('MATLAB:pareto:NotEnoughInputs'));
    end
    y = args{1};
    y = matlab.graphics.chart.internal.datachk(y,'numeric');
    
    cutoff = .95;
    names = compose("%d",1:numel(y));
    
    if nargs == 2 
        if isscalar(args{2})
            cutoff = args{2};
            names = compose("%d",1:numel(y));
        else
            names = args{2};
            names=string(names);
        end
    elseif nargs == 3
        names = string(args{2});
        cutoff = args{3};
    end
    
    if ~isvector(y) || isscalar(y)
        error(message('MATLAB:pareto:YMustBeVector'));
    end
    
    % If the data are complex, disregard any complex component, and warn the user.
    if (~isreal(y))
        warning(message('MATLAB:specgraph:private:specgraph:UsingOnlyRealComponentOfComplexData'));
        y = real(y);
    end
    
    if ~isnumeric(cutoff) || cutoff<0 || cutoff>1
        error(message('MATLAB:pareto:InvalidThreshold'))
    end
    
    y = y(:);
    [yy, ndx] = sort(y);
    yy = flipud(yy);
    ndx = flipud(ndx);
    
    cax = newplot(cax);
    parent = cax.Parent;
    fig = ancestor(cax, 'figure');

    % Error if AutoResizeChildren is 'on'
    if isprop(parent,'AutoResizeChildren') && strcmp(parent.AutoResizeChildren,'on')
        error(message('MATLAB:pareto:AutoResizeChildren'))
    end

    hold_state = ishold(cax);
    
    h = bar(cax, 1:length(y), yy);
    
    h = [h; line(1:length(y), cumsum(yy), 'Parent', cax)];
    ysum = sum(yy);
    
    if ysum == 0
        ysum = eps;
    end
    k = min(find(cumsum(yy) / ysum > cutoff, 1), 10);
    
    if isempty(k)
        k = min(length(y), 10);
    end
    
    xLim = [.5 k+.5];
    yLim = [0 ysum];
    set(cax, 'XLim', xLim);
    set(cax, 'XTick', 1:k, 'XTickLabel', names(ndx(1:k)), 'YLim', yLim);
    

    % Capture the state of the parent GridLayout when present so that it 
    % can be restored.
    origGLconfig = [];
    if isa(parent,'matlab.ui.container.GridLayout')
        origGLconfig = {parent.RowHeight, parent.ColumnWidth};
    end

    % Hittest should be off for the transparent axes so that click and
    % mouse motion events are attributed to the opaque axes.
    raxis = axes('Color', 'none', 'XGrid', 'off', 'YGrid', 'off', ...
        'YAxisLocation', 'right', 'XLim', xLim, 'YLim', yLim, ...
        'HitTest', 'off', 'HandleVisibility', get(cax, 'HandleVisibility'), ...
        'Parent', parent);
    setupAxesInGridLayout(cax, raxis, origGLconfig) 
    resizePareto(cax, raxis)
    
    yticks = get(cax, 'YTick');
    if max(yticks) < .9 * ysum
        yticks = unique([yticks, ysum]);
    end
    set(cax, 'YTick', yticks)
    yticklabels=compose("%0.0f%%",100*yticks/ysum);
    set(raxis, 'YTick', yticks, 'YTickLabel', yticklabels, 'XTick', []);
    set(fig, 'CurrentAxes', cax);
    linkaxes([raxis, cax],'xy');
    addlistener(cax, 'MarkedClean', @(~,~) resizePareto(cax, raxis));

    if ~isa(parent,'matlab.graphics.layout.Layout')
        raxis.PositionConstraint = 'innerposition';
        if ~hold_state
            hold(cax, 'off');
            set(fig, 'NextPlot', 'replacechildren');
        end
    end

    % Add MetaDataSevice flag
    if ~isprop(cax, 'FDT_Accessor')
        prop = addprop(cax, 'FDT_Accessor');
        prop.Transient = true;
        prop.Hidden = true;
    end
    
    cax.FDT_Accessor = 'pareto';
    
    if nargout > 0
        hh = h;
        ax = [cax raxis];
    end
end

function resizePareto(cax, raxis)
if isvalid(raxis) && ( ...
        ~isequal(raxis.Layout, cax.Layout) || ...
        ~isequal(raxis.Units, cax.Units) || ...
        ~isequal(raxis.InnerPosition, cax.InnerPosition))
    
    % In a grid layout, only attempt to sync the two Axes's positions if
    % they do not share the same tile.
    inGridLayout = isa(cax.Layout,'matlab.ui.layout.GridLayoutOptions');
    if isempty(cax.Layout) || (inGridLayout && ~isequal(raxis.Layout, cax.Layout))
        raxis.Units = cax.Units;
        raxis.InnerPosition = cax.InnerPosition;
    else
        % In TiledChartLayout it is sufficient for the axes to share the same layout info.
        raxis.Layout = cax.Layout;
    end
end
end

function setupAxesInGridLayout(cax, raxis, origGLconfig)

if ~isempty(origGLconfig)

    % Check if the addition of raxis has modified the size of the GridLayout.
    currGLconfig = {cax.Parent.RowHeight, cax.Parent.ColumnWidth};
    if ~isequal(currGLconfig,origGLconfig)

        % Determine where to put the new axes
        numInd = numel(origGLconfig{1}) * numel(origGLconfig{2});
        if numInd == 1 
            % If cax occupies the only GridLayout tile, we have to put raxis
            % in that same tile. Recursive resize events will be triggered 
            % in this case if we attempt to sync their positions, so warn
            % here to alert users this is not enabled.
            warning(message('MATLAB:pareto:UIGridLayout'));
            raxis.Layout = cax.Layout;
        else
            % Otherwise, find a separate tile to put raxis in.
            caxInd = sub2ind([numel(origGLconfig{1}), numel(origGLconfig{2})],cax.Layout.Row, cax.Layout.Column);
            [raxis.Layout.Row, raxis.Layout.Column] = ind2sub([numel(origGLconfig{1}), numel(origGLconfig{2})], mod(caxInd, numInd)+1);
        end

        % Restore the original grid layout size
        cax.Parent.RowHeight = origGLconfig{1};
        cax.Parent.ColumnWidth = origGLconfig{2};
    end
end

end
