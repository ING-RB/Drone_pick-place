function layoutBubbles(obj)
%

%   Copyright 2020 The MathWorks, Inc.

% This method lays out bubbles. If the bubbles are ungrouped, or there is
% only one group, the bubbles are laid out based on the current aspect
% ratio. If there are multiple groups, each group is laid out with an aspect
% ratio of 1, and then the groups are treated like bubbles and laid out
% with the current aspect ratio.
%

aspectratio=obj.AspectRatio;
if isempty(aspectratio)
    aspectratio=obj.computeAspectRatio;
    obj.AspectRatio=aspectratio;
end

% Get sorted Radii
r=obj.XYR(3,:);

groups=obj.GroupData_I;
if iscellstr(groups) %#ok<ISCLSTR>
    % Cast cellstrs to string to allow eq in lieu of strcmp
    groups=string(groups);
end

if isempty(groups) || all(groups==groups(1))
    % No groups or just one group
    obj.XYR(1:2,:)=matlab.graphics.internal.layoutBubbleCloud(r,aspectratio);
else
    % Grouped data
    groups=groups(obj.RadiusIndex);
    obj.XYR=layoutGroupedBubbles(obj.XYR,groups,aspectratio);
end
end



function XYR=layoutGroupedBubbles(XYR,groups,aspectratio)
% Group bubble layout

% Pull out an 'undefined' group
undefined_ind=ismissing(groups);

% Layout each group, using ar=1,. storing the radius of a
% circle that encloses the group
grplist=unique(groups(~undefined_ind));
groupradius=nan(numel(grplist),1);
for g=1:numel(grplist)
    gp_ind=groups==grplist(g);
    if any(gp_ind)
        r=XYR(3,gp_ind);
        xy=matlab.graphics.internal.layoutBubbleCloud(r,1);
        groupradius(g)=max(sqrt(sum(xy.^2))+r);
        XYR(1:2,gp_ind)=xy;
    end
end

% Layout any nan/undefined as a separate group
if any(undefined_ind)
    r=XYR(3,undefined_ind);
    xy=matlab.graphics.internal.layoutBubbleCloud(r,1);
    groupradius(end+1)=max(sqrt(sum(xy.^2))+r);
    XYR(1:2,undefined_ind)=xy;
end

% Layout the circles that contain the groups
groupxyr=nan(3,numel(groupradius));
groupxyr(3,:)=groupradius;
[gp_sortr,gp_sortind]=sort(groupradius,'descend');
groupxyr(1:2,gp_sortind)=matlab.graphics.internal.layoutBubbleCloud(gp_sortr,aspectratio);

% Apply the group bubble position as an offset
for g=1:numel(grplist)
    gp_ind=groups==grplist(g);
    XYR(1:2,gp_ind)=XYR(1:2,gp_ind)+groupxyr(1:2,g);
end

% Offset undefined group if it exists
if any(undefined_ind)
    XYR(1:2,undefined_ind)=XYR(1:2,undefined_ind)+groupxyr(1:2,end);
end
end

% LocalWords:  ungrouped cellstrs
