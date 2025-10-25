function [x0,y0,y1,x1] = getAxesGridPositionForOuterLabels(h,ax,units)

currentUnits = string(get(ax(:),'Units'));
set(ax,'Units',units);
[nr,nc] = size(ax);

if nc > 1
    bottomRowPosition = cell2mat(get(ax(end,:),'Position'));
    bottomRowInset = cell2mat(get(ax(end,:),'TightInset'));
    topRowPosition = cell2mat(get(ax(1,:),'Position'));
    topRowInset = cell2mat(get(ax(1,:),'TightInset'));
    
else
    bottomRowPosition = get(ax(end,:),'Position');
    bottomRowInset = get(ax(end,:),'TightInset');
    topRowPosition = get(ax(1,:),'Position');
    topRowInset = get(ax(1,:),'TightInset');
end
if ax(end,1).XAxis.Exponent ~= 0
    y0 = min(bottomRowPosition(:,2) - bottomRowInset(:,2)/2);
else
    y0 = min(bottomRowPosition(:,2) - bottomRowInset(:,2));
end
y1 = max(topRowPosition(:,2) + topRowPosition(:,4) + topRowInset(:,4));

if nr > 1
    leftColumnPosition = cell2mat(get(ax(:,1),'Position'));
    leftColumnInset = cell2mat(get(ax(:,1),'TightInset'));
else
    leftColumnPosition = get(ax(:,1),'Position');
    leftColumnInset = get(ax(:,1),'TightInset');
end
x0 = min(leftColumnPosition(:,1) - leftColumnInset(:,1));

if nargout > 3
    if nr > 1
        rightColumnPosition = cell2mat(get(ax(:,end),'Position'));
        rightColumnInset = cell2mat(get(ax(:,end),'TightInset'));
    else
        rightColumnPosition = get(ax(:,end),'Position');
        rightColumnInset = get(ax(:,end),'TightInset');
    end
    x1 = max(rightColumnPosition(:,1) + rightColumnPosition(:,3) + rightColumnInset(:,3));
end

set(ax(:),'Units',currentUnits(1));
end