function setMarkerColor(obj)
%

%   Copyright 2020 The MathWorks, Inc.

% Set the Marker color bubbles based on color/alpha properties
% and GroupData

mfc=obj.FaceColor;
mec=obj.EdgeColor;

mfcflat=strcmp(mfc,'flat');
mecflat=strcmp(mec,'flat');
hasgroups=~isempty(obj.GroupData_I);

if hasgroups
    groups=obj.GroupData_I;
    [groupname, groupcolor, bubblegroupind] = ...
        calculateGroupColor(groups,obj.ColorOrder,obj.RadiusIndex);
    groupedbubbleclr=groupcolor(bubblegroupind,:);
    obj.setLegendScatters(groupname,groupcolor,mfc,mec)
else
    obj.setLegendScatters([]);
end

if strcmp(mfc,'none')
    facebinding='none';
    facedata=[];
elseif mfcflat && hasgroups
    facebinding='discrete';
    facedata=groupedbubbleclr;
elseif mfcflat && ~hasgroups
    facebinding='object';
    facedata=obj.ColorOrder(1,:);
else % colorspec or rgb
    facebinding='object';
    facedata=mfc;
end
if strcmp(mec,'none')
    edgebinding='none';
    edgedata=[];
elseif mecflat && hasgroups
    edgebinding='discrete';
    edgedata=groupedbubbleclr;
elseif mecflat && ~hasgroups
    edgebinding='object';
    edgedata=obj.ColorOrder(1,:);
else % colorspec or rgb
    edgebinding='object';
    edgedata=mec;
end

hColorIter = matlab.graphics.axis.colorspace.IndexColorsIterator;
hColorIter.CDataMapping = 'scaled';

hColorIter.Colors=facedata;
hColorIter.AlphaData=obj.FaceAlpha;
colordata = obj.Axes.ColorSpace.TransformTrueColorToTrueColor(hColorIter);
obj.Marker.FaceColorBinding=facebinding;
obj.Marker.FaceColorType=colordata.Type;
obj.Marker.FaceColorData=colordata.Data;

hColorIter.Colors=edgedata;
hColorIter.AlphaData=1;
colordata = obj.Axes.ColorSpace.TransformTrueColorToTrueColor(hColorIter);
obj.Marker.EdgeColorBinding=edgebinding;
obj.Marker.EdgeColorType=colordata.Type;
obj.Marker.EdgeColorData=colordata.Data;
end

function [groupname, groupcolor, groupind]=calculateGroupColor(groups,colororder,radiusindex)
% groupname is the name of groups for legend, groupcolor is the color of
% markers in that group, groupind is the row of groupname/groupcolor for
% each marker.

if isnumeric(groups)
    missingstring="NaN";
else
    missingstring="<missing>";
end

% Calculate colors for groups;
if ~iscategorical(groups)
    groups=categorical(groups);
end

groupind=double(groups);
groupname=categories(groups);

if any(isnan(groupind))
    groupind(isnan(groupind))=numel(groupname)+1;
    groupname{end+1}=missingstring;
end

ncolors=numel(groupname);

% Select groupcolor from colororder
groupcolorind=mod((1:ncolors)-1,height(colororder))+1;
groupcolor=colororder(groupcolorind,:);

% Order groupind like VertexData
groupind=groupind(radiusindex);

end

% LocalWords:  colorspec groupname groupcolor groupind colororder
