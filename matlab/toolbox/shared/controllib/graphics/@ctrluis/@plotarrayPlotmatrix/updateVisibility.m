function updateVisibility(h)
% Update plot visibility and recursively apply REFRESH to subgrids

%   Copyright 2015-2020 The MathWorks, Inc.

Size = size(h.Axes);
RowVis = h.Visible & h.RowVisible;
ColVis = (h.Visible & h.ColumnVisible)';
NewVis = RowVis(:,ones(1,Size(2))) & ColVis(ones(1,Size(1)),:);

if ishghandle(h.Axes(1),'axes')
    % Apply new visibility to HG axes and set zoom property
    % based on visibility of axis
    hax = h.Axes(NewVis);
    set(hax,'Visible','on','ContentsVisible','on')
    bh = hgbehaviorfactory('Zoom');
    set(bh, 'Enable', true);
    hgaddbehavior(hax,bh);

    hax = h.Axes(~NewVis);
    % Turn off legends
    for ct = 1:length(hax(:))
        legend(double(hax(ct)),'off')
    end
    set(hax,'Visible','off','ContentsVisible','off');
    bh = hgbehaviorfactory('Zoom');
    set(bh, 'Enable', false);
    hgaddbehavior(hax,bh);
else
   % Update visibility of each subgrid
   set(h.Axes(NewVis),'Visible',1)
   set(h.Axes(~NewVis),'Visible',0)
   % Recursive call to REFRESH
   % RE: Apply to ALL subarrays to properly update visibility of HG axes
   for ct=1:prod(Size)
      refresh(h.Axes(ct))
   end
end   
