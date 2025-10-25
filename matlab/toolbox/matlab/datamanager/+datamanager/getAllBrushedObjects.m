function selected_sibs = getAllBrushedObjects(gobj)
%

% Copyright 2008-2015 The MathWorks, Inc.

% Get all the objects in the graphic container which have been brushed.
% Be sure to include the peer axes for any plotyy axes.

selected_sibs = findobj(gobj,'-property','type','-function',...
    @(x) isprop(x,'BrushData') && ~isempty(get(x,'BrushData')) && any(x.BrushData(:)>0));
for k=1:numel(gobj)
    if isappdata(gobj(k),'graphicsPlotyyPeer')
        selected_yysibs = findobj(getappdata(gobj(k),'graphicsPlotyyPeer'),'-function',...
            @(x) isprop(x,'BrushData') && ~isempty(get(x,'BrushData')) && any(x.BrushData(:)>0));
        selected_sibs = [selected_sibs(:);selected_yysibs(:)]';
    end
    
    % Check for objects brushed using behavior objects
    custom = findobj(gobj(k).Parent,'HandleVis','on','-not',{'Behavior',struct},'-function',...
        @localHasBrushBehavior,'HandleVis','on');
    % Add objects brushed by enabled behavior objects
    if ~isempty(custom)
        
        Iinclude = false(length(custom),1);
        for j=1:length(custom)
            
            % for histogram like objects (histogram, histogram2 and
            % categoricalhistogram) it is not enough to look at the behavior object
            % only, since the object must be linked in order to be brushed.
            % Therefore, look at the BrushValues property and if it has a non
            % zero value, then include it.
            if isprop(custom(j),'BrushValues') && (isempty(custom(j).BrushValues) || ~any(custom(j).BrushValues(:)))
                continue
            end
            
            bh = hggetbehavior(custom(j),'Brush');
            Iinclude(j) =  bh.Enable;
            
        end
        selected_sibs = [selected_sibs(:); custom(Iinclude)];
    end
    
end



function state = localHasBrushBehavior(h)

state = ~isempty(hggetbehavior(h,'Brush','-peek'));

