function doShowInspector = shouldShowEmbeddedInspector(hFig)

%    Returns true when embedded inspector in a side panel needs to be shown, else false.
%    Must return false for undocked java figure, undocked uifigure which show up as
%    standalone figures in MATLAB Online. For undocked java figures in MO, most reliable way as of now
%    is to use MenuBar property value as 'none'. Otherwise, we can't differentiate between this and mgg

%    FOR INTERNAL USE ONLY -- This function is intentionally undocumented
%    and is intended for use only with the scope of function in the MATLAB
%    Engine APIs.  Its behavior may change, or the function itself may be
%    removed in a future release.

% Copyright 2022-2024 The MathWorks, Inc.

doShowInspector = all(~isempty(hFig)) && ...
                  all(isvalid(hFig)) && ...
                  all(arrayfun(@(h) strcmpi(h.DefaultTools, 'toolstrip'), hFig)) && ...
                  all(arrayfun(@(h) strcmpi(h.Visible, 'on'), hFig)) ;
if ~doShowInspector
   return
end

if feature('webui')
   % In the JSD all figures except uifigure should use an embedded Inspector
   % SidePanel   
   doShowInspector = all(arrayfun(@(h) ~matlab.ui.internal.FigureServices.isUIFigure(h), hFig));
elseif matlab.graphics.internal.toolstrip.FigureToolstripManager.isMATLABOnline()
    % In MOL all figures except uifigures and undocked mgg figures should
    % use the embedded Inspector SidePanel. The only way to detect the
    % latter is to use the presence of a MenuBar property value that is not
    % 'none'. Note that mgg figures that appear to be docked in MOL (e.g.
    % figures created by "surf(peaks)") will also be caught up by this
    % condition and so show their Inspector in a separate window. This
    % limitation will remain until we have a reliable way to distinguish
    % the two cases
    doShowInspector  = all(arrayfun(@(h) ~matlab.ui.internal.FigureServices.isUIFigure(h),hFig)) && ...
                  all(isprop(hFig, 'MenuBar')) && ... 
                  all(strcmpi(get(hFig, 'MenuBar'), 'none'));    
else
    % In the Java desktop there is no embedded Inspector SidePanel
    doShowInspector  = false;
end

 