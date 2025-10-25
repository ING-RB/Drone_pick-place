function printToFigure(this,printfig) 
% PRINTTOFIGURE Copy the respplot to a figure for printing
%
 
% Copyright 2014-2017 The MathWorks, Inc.

CopyAx = findobj(getaxes(this.AxesGrid),'flat','Visible','on');
BackAx = get(this.AxesGrid,'BackgroundAxes');

% Determine if legends are on for each axes
naxes = length(CopyAx);
for ct = naxes:-1:1
    leg = get(CopyAx(ct),'Legend');
    if isempty(leg)
        legendon(ct) = struct('on',false,'pos',[]);
    else
        legendon(ct) = struct('on',true,'pos',get(leg,'position'));
    end
end

% ---- Get the labels
labels1 = [get(BackAx,{'XLabel','YLabel','Title'});...
        get(CopyAx,{'XLabel','YLabel','Title'})];
if ~iscell(labels1)
    labels1 = {labels1};
end
labels1 = reshape([labels1{:,:}],size(labels1));
%---- Get label properties
PropVal = get(labels1,{'Position','Visible','Color'});

%---- Copy axes to the new figure
h = copyobj(CopyAx,printfig);
% copy background axes after data axes for legend visibility
B = copyobj(BackAx,printfig);

% Re: Need to copy annotation property until copyobj issue for hggroup is fixed
% g394314
CopyAxHGGroups = findobj(CopyAx,'type','hggroup');
hHGGroups = findobj(h,'type','hggroup');
for ct = 1:length(CopyAxHGGroups)
       hCopyAxAnnotations = get(CopyAxHGGroups(ct),'Annotation'); 
       hhAnnotations = get(hHGGroups(ct),'Annotation');
       hhAnnotations.LegendInformation.IconDisplayStyle = hCopyAxAnnotations.LegendInformation.IconDisplayStyle; 
       % Remove custom plot tools behavior
       localRemovePlotToolsBehavior(hHGGroups(ct));
end

% Set legend state to that of original figure
for ct = 1:naxes
    if legendon(ct).on
        leg = legend(h(ct),'show');
        set(leg,'position',legendon(ct).pos);
    end
end

% If the background axes have a legend, this needs to be recreated in the
% copy, because the background axes may be empty, not having lines
hFig = get(BackAx, 'Parent');
hChildren = hFig.Children;
lookingFor = {'ExperimentPlot Legend',  'ResidualPlot Legend'};
tf_array = arrayfun(@(e) any(strcmp(e.Tag, lookingFor)), hChildren);
if any(tf_array)
    loc = find(tf_array);
    loc = loc(1);   % there should only be 1 legend for the axes
    hLegend = hChildren(loc);
    % Transfer legend if it is visible on original axes
    if strcmp(hLegend.Visible, 'on')
        hLine = BackAx.UserData.hLine;
        txt = {BackAx.UserData.txt};
        legend(B, hLine, txt);
    end
end

%---- Get the axes object properties
labels2 = get([B;h],{'XLabel','YLabel','Title'});
if ~iscell(labels2)
    labels2 = {labels2};
end
labels2 = reshape([labels2{:,:}],size(labels2));
%---- Store the initial position of the title in the new figure (g1105328).
%The title is stored in the upper-right corner of the labels2 array, but
%PropVal is flattened.
printfigTitlePos = get(labels2(1,end),'Position');
%---- Apply old properties
set(labels2,{'Position','Visible','Color'},PropVal)
set(labels2(1,end),'Position',printfigTitlePos);
set(labels2,'Units','Normalized');
%Adjust backaxis title position, as backaxis and copy axis are different.
labels2(1,3).Position(2) = 1.03;
% Enable HitTest so labels are editable in plottools
set(labels2,'HandleVisibility','on','HitTest','on');
%---Turn off buttondownfcn, deletefcn, etc.
set([h(:);B(:)],'Units','Normalized');
kids = get(h,{'children'});
if iscell(kids)
    kids = cat(1,kids{:});
else
    kids = kids(:);
end
hggroupkids = get(hHGGroups,{'children'});
if iscell(hggroupkids)
    hggroupkids = cat(1,hggroupkids{:});
else
    hggroupkids = hggroupkids(:);
end

%---Clear all callbacks/uicontextmenus/tags/userdata associated with new copies
set([h(:);kids(:);hggroupkids(:)],'DeleteFcn','','ButtonDownFcn','','UIContextMenu',[],'UserData',[],'Tag','');

% Clear appdata
for cnt = 1:length(h)
    % Remove custom plot tools behavior
    localRemovePlotToolsBehavior(h(cnt));
  
    if isappdata(h(cnt),'WaveRespPlot')
         rmappdata(h(cnt),'MWBYPASS_grid');
         rmappdata(h(cnt),'MWBYPASS_title');
         rmappdata(h(cnt),'MWBYPASS_xlabel');
         rmappdata(h(cnt),'MWBYPASS_ylabel');
         rmappdata(h(cnt),'MWBYPASS_axis');
         rmappdata(h(cnt),'WaveRespPlot');
    end
end

% Clear datacursor behavior
for cnt = 1:length(hggroupkids)
    localRemoveDataCursorBehavior(hggroupkids(cnt));
end
end

function localRemovePlotToolsBehavior(obj)
%Remove custom plot tools behavior
bb = get(obj,'Behavior');
updatebehavior = false;

if isfield(bb,'plottools')
    bb = rmfield(bb,'plottools');
    updatebehavior = true;
end
if isfield(bb,'plotedit')
    bb = rmfield(bb,'plotedit');
    updatebehavior = true;
end

if updatebehavior
    set(obj,'Behavior',bb);
end
end

function localRemoveDataCursorBehavior(obj)
%Remove custom data cursor behavior
bb = get(obj,'Behavior');

if isfield(bb,'datacursor')
    bb = rmfield(bb,'datacursor');
    set(obj,'Behavior',bb);
end
end