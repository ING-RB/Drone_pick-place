function [l,c,m] = nextstyle(ax,autoColor,autoStyle,leaveSeriesIndexAlone)
% This function is undocumented and may change in a future release.

%   Copyright 1984-2023 The MathWorks, Inc.

%NEXTSTYLE Get next plot linespec
%   [l,c,m] = nextstyle(ax,autoColor,autoStyle,leaveSeriesIndexAlone) gets 
%   the next line style, color, and marker. If leaveSeriesIndexAlone is 
%   false and either autoColor or autoStyle was specified, the Axes
%   NextSeriesIndex will be incremented. If the Axes is currently in the 
%   colororder compatibility layer (i.e. NextSeriesIndex is 0)
%   ColorOrderIndex or LineStyleOrderIndex will be incremented. 

co = get(ax,'ColorOrder');
lo = get(ax,'LineStyleOrder');

% If the colororder is empty, default by assuming it is black. 
if isempty(co)
   co = [0 0 0];
end

ci = [1 1];

ci(1) = get(ax,'ColorOrderIndex');
ci(2) = get(ax,'LineStyleOrderIndex');

cm = size(co,1);
lm = size(lo,1);

if isa(lo,'cell')
  [l,~,m] = colstyle(lo{mod(ci(2)-1,lm)+1});
else
  [l,~,m] = colstyle(lo(mod(ci(2)-1,lm)+1,:));
end
c = co(mod(ci(1)-1,cm)+1,:);

% If nextstyle is called with leaveSeriesIndexAlone set to true, the
% caller is responsible for incrementing the NextSeriesIndex, so do not
% increment the NextSeriesIndex here. If leaveSeriesIndexAlone is
% false, and either a color or style was requested, then this call to
% getNextSeriesIndex will increment the NextSeriesIndex.
seriesIndex = ax.getNextSeriesIndex(~leaveSeriesIndexAlone && (autoColor || autoStyle));

if seriesIndex == 0
    % If NextSeriesIndex on the axes is 0, fall back to the old mechanism
    % for tracking the ColorOrderIndex and LineStyleOrderIndex.
    if autoStyle && (~autoColor || ci(1) == cm)
        ci(2) = mod(ci(2),lm) + 1;
    end
    if autoColor
        ci(1) = mod(ci(1),cm) + 1;
    end
    
    set(ax,'ColorOrderIndex',ci(1));
    set(ax,'LineStyleOrderIndex',ci(2));
end

if isempty(l) && ~isempty(m)
  l = 'none';
end
if ~isempty(l) && isempty(m)
  m = 'none';
end

end