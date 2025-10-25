function [cout, hand] = contour(varargin)
    %CONTOUR Contour plot.
    %   CONTOUR(Z) draws a contour plot of matrix Z in the x-y plane, with
    %   the x-coordinates of the vertices corresponding to column indices
    %   of Z and the y-coordinates corresponding to row indices of Z. The
    %   contour levels are chosen automatically.
    %
    %   CONTOUR(X,Y,Z) draws a contour plot of Z using vertices from the
    %   mesh defined by X and Y. X and Y can be vectors or matrices.
    %
    %   CONTOUR(Z,N) and CONTOUR(X,Y,Z,N) draw N contour lines, choosing
    %   the levels automatically.
    %
    %   CONTOUR(Z,V) and CONTOUR(X,Y,Z,V) draw a contour line for each
    %   level specified in vector V.  Use CONTOUR(Z,[v v]) or
    %   CONTOUR(X,Y,Z,[v v]) to draw contours for the single level v.
    %
    %   CONTOUR(AX, ...) plots into the axes AX.
    %
    %   [C,H] = CONTOUR(...) returns contour matrix C and a handle, H, to
    %   a contour object. These can be used as inputs to CLABEL. The
    %   structure of a contour matrix is described in the contour
    %   documentation.
    %
    %   CONTOUR(..., LineSpec) draws the contours using the line type and
    %   color specified by LineSpec (ignoring marker symbols).
    %
    %   To specify additional contour properties, you can follow the
    %   arguments in any of the syntaxes described above with name-value
    %   pairs.
    %
    %   Example:
    %      [c,h] = contour(peaks);
    %      clabel(c,h)
    %
    %   See also CONTOUR3, CONTOURF, CLABEL.
        
    % Copyright 1984-2022 The MathWorks, Inc.
    
    % Determine the number of outputs
    nout = nargout;
    
    [~, cax, args] = parseplotapi(varargin{:},'-mfilename',mfilename);

    narginchk(1, Inf);
    [pvpairs, ~, ~, errmsg, warnmsg] = matlab.graphics.chart.internal.contourobjHelper('parseargs', false, args{:});
    if ~isempty(errmsg)
        error(errmsg);
    end
    if ~isempty(warnmsg)
        warning(warnmsg);
    end
    
    % Prepend pvpairs specific to contour
    pvpairs = [{ ...
        'EdgeColor_I', 'flat', ...
        'FaceColor_I', 'none', ...
        'ShowText_I', 'off', ...
        'Is3D_I', 'off'} ...
        pvpairs];
    
    if isempty(cax) || ishghandle(cax, 'axes')
        showInteractionInfoPanel = isempty(cax) && isempty(get(groot,'CurrentFigure'));
        cax = newplot(cax);
        parax = cax;
        nextPlot = cax.NextPlot;
        if showInteractionInfoPanel
            % Maybe open the Interaction Info Panel
            matlab.graphics.internal.InteractionInfoPanel.maybeShow(cax);
        end            
    else
        parax = cax;
        cax = ancestor(cax, 'axes');
        nextPlot = 'add';
    end

    % Create contour with parent so defacultCreateFcn gets called.
    h = matlab.graphics.chart.primitive.Contour(pvpairs{:}, 'Parent', parax);
    
    if ismember(nextPlot, {'replace','replaceall'})
        view(cax, 2);
        cax.Box = 'on';
        cax.BoxStyle = 'full';
        cax.Layer = 'top';
        grid(cax,'off');
    end
    
    set(cax, 'XLimSpec', 'tight');
    set(cax, 'YLimSpec', 'tight');
    set(cax, 'ZLimSpec', 'tight');
    
    if nout > 0
        cout = h.ContourMatrix;
    end
    if nout > 1
        hand = h;
    end
end
