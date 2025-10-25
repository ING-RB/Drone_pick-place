function objs = callbackinfo_get_selection(h)
%

% Copyright 2004-2016 The MathWorks, Inc.

objs = [];
switch class(h.uiObject)
    %
    % Stateflow Editor cases
    %
    case {'Stateflow.Chart', 'Stateflow.StateTransitionTableChart', 'Stateflow.ReactiveTestingTableChart'}
        objs = sf_get_selection_from_cbinfo_l(h);
        
    %
    % Simulink Editor cases
    %
  case {'Simulink.BlockDiagram', 'Simulink.SubSystem'}
        s = find_system( h.uiObject.Handle, 'SearchDepth', 1, ...
            'FindAll','on', ... % blocks AND lines AND annotations
            'FollowLinks','on',... % even if we're looking inside a link
            'LookUnderMasks','all',...  % or inside a mask
            'MatchFilter', @Simulink.match.allVariants,... % or if a selected block is an inactive variant
            'IncludeCommented','on',... % or commented out
            'SkipLinks','on',... % but don't try to resolve library links
            'Selected','on');
        if ~isempty(s)
            s = setdiff(s,h.uiObject.Handle); % exclude the system itself
            if ~isempty(s)
                objs = get_param(s,'Object');
                if iscell(objs)
                    % get_param returns a cell array of objects if "s"
                    % contains more than one handle.  We need to return a
                    % column vector of objects.
                    objs = [objs{:}]';
                end
            end
        end
      
    %
    % Model Explorer
    %
    case 'DAStudio.Explorer'
        imME = DAStudio.imExplorer(h.uiObject);
        objs = imME.getSelectedListNodes;
end


    
function objs = sf_get_selection_from_cbinfo_l(cbinfo)
    chart = cbinfo.uiObject.id;
    r = sfroot;
    selectedIds = sf('SelectedObjectsIn', chart);
    
    if isempty( selectedIds ) && cbinfo.isContextMenu
        subviewerId = SFStudio.Utils.getSubviewerId( cbinfo );
        if isempty( sf( 'get', subviewerId, 'chart.isa' ) )
            selectedIds = subviewerId;
        end
    end
    
    if ~isempty(selectedIds)
       objs = r.idToHandle(selectedIds);
    else
        objs = [];
    end
