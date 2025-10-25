function varargout = MEView_cb(dlg, fcn, varargin)
%

%   Copyright 2009-2011 The MathWorks, Inc.

if ~isempty(dlg)
    manager = dlg.getSource();
end

switch (fcn)
    case 'doFilterProperties'
        if isempty(manager.Timer)
            manager.Timer = DAStudio.Timer;
        end
        if ~manager.Timer.isActive
            manager.Timer.setCallback(@()dlg.refresh);
            manager.Timer.startSingle(200);
        end
        
    case 'doAdd'        
        view = varargin{1};
        doAdd(dlg, view);
    
    case 'doRemove'
        view = varargin{1};
        doRemove(dlg, view);
        
    case 'doUp'
        view = varargin{1};
        doUp(dlg, view);
        
    case 'doDown'
        view = varargin{1};
        doDown(dlg, view);
        
    case 'doReorderProperties'
        view          = varargin{1};
        proposedOrder = varargin{2};
        
        doReorderProperties(dlg, view, proposedOrder);
        
    case 'doEnableDisableButtons'        
        view = manager.ActiveView;
        if ~isempty(view.Properties)

            allProps = findobj(view.Properties, 'isVisible', true, ...
                'isTransient', false, 'isReserved', false);
            rows = dlg.getSelectedTableRows('view_columns_table');

            % Enable disable up/down buttons
            % Use same logic which we used for up and down move.
            tempRows = int32(rows) - 1; 
            dlg.setEnabled('view_up_button', isempty(find(tempRows < 0, 1)))
            tempRows = rows + 1;
            dlg.setEnabled('view_down_button', isempty(find(tempRows > (length(allProps) - 1), 1)));
        end
        
    case 'doAddProperty'
        view = varargin{1};
        property = varargin{2};
        location = varargin{3};
        doAddProperty(view, property, location);
        
    otherwise
        DAStudio.error('modelexplorer:DAS:UnknownAction');
    end

%
% Add properties to the view.
%
function doAdd(dlg, view)
    % don't bother doing anything if the edit text & list selection is empty
    text     = dlg.getWidgetValue('view_search_edit');
    indices  = dlg.getWidgetValue('view_properties_list') + 1;
    if isempty(text) && isempty(indices)
        return;
    else
        % If there is a text, it should be a valid matlab name.
        if ~isempty(text) && ~isValidPropertyName(text)
            return;
        end
    end
    
    % find out what properties we want to add (list selection takes precedence)
    if ~isempty(indices)
        imd   = DAStudio.imDialog.getIMWidgets(dlg);
        list  = imd.find('Tag', 'view_properties_list');
        items = list.getListItems;
        props = items(indices);
    else
        props = {strtrim(text)};
    end
    % Add property after selected row. In the case of multi-select, it is after
    % the last selection.
    rows = dlg.getSelectedTableRows('view_columns_table');
    propertyAfter = '';
    if ~isempty(rows)
       visProperties = findobj(view.Properties, 'isVisible', true, ...
           'isTransient', false, 'isReserved', false);
       propertyAfter = visProperties(rows(end)+1).Name;
    end
    view.addProperty(props, propertyAfter);
    % Select the last property added
    viewProperties = findobj(view.Properties, 'isVisible', true, ...
        'isTransient', false, 'isReserved', false);
    index = find(strcmpi(get(viewProperties, 'Name'), props{end}));
    if ~isempty(index) && index > 0
        dlg.selectTableRow('view_columns_table', index - 1);
    else
        dlg.selectTableRow('view_columns_table', 0);
    end
    DAStudio.MEView_cb(dlg, 'doEnableDisableButtons');
end

%
%
% doRemove
%
% Remove property from the view.
%
function doRemove(dlg, view)
    % don't bother doing anything if the table selection is empty
    rows = dlg.getSelectedTableRows('view_columns_table');
    if isempty(rows) || isempty(view.Properties)
        return;
    end
    
    visibleProperties = findobj(view.Properties, 'isVisible', true, ...
        'isTransient', false, 'isReserved', false);
    propsToRemove = cell(length(rows), 1);
    for i = 1:length(rows)
        propsToRemove{i} = visibleProperties(rows(i)+1).Name;
    end
    view.removeProperty(propsToRemove);
    DAStudio.MEView_cb(dlg, 'doEnableDisableButtons');
end

%
% Move property up
%
function doUp(dlg, view)
    % Return if view does not have anything
    if isempty(view.Properties)
        return;
    end
    rows = dlg.getSelectedTableRows('view_columns_table');
    % Before continuing, validate
    tempRows = int32(rows) - 1;
    if isempty(find(tempRows < 0, 1))
        % We can move.
        propsToMove = cell(length(rows), 2);
        visProperties = findobj(view.Properties, 'isVisible', true, ...
            'isTransient', false, 'isReserved', false);
        for i = 1:length(rows)
            propToMove = visProperties(rows(i) + 1).Name;
            rowToMoveBefore = rows(i) - 1;
            if ~isempty(find(rows == rowToMoveBefore))
                rowToMoveBefore = rows(1) - 1;
            end
            propToMoveBefore = visProperties(rowToMoveBefore + 1).Name;        
            propsToMove{i,1} = propToMove;
            propsToMove{i,2} = propToMoveBefore;        
        end
        % Move
        view.disableLiveliness;
         vProps = view.Properties;
        if length(rows) == 1
             vProps = swapProperties(vProps, propsToMove{1}, propsToMove{2});          
        else
            num = length(propsToMove);
            for i = 1:num
                vProps = swapProperties(vProps, char(propsToMove{i, 1}), char(propsToMove{i, 2}));            
            end
        end    
        view.enableLiveliness;
        view.Properties = vProps;
        dlg.selectTableRows('view_columns_table', double(rows-1));
    end
    DAStudio.MEView_cb(dlg, 'doEnableDisableButtons');
end


%
% Move property down
%
function doDown(dlg, view)
% Return if view does not have anything
    if isempty(view.Properties)
        return;
    end
    rows = dlg.getSelectedTableRows('view_columns_table');
    % First validate.
    tempRows = rows(end:-1:1);
    % Moving down so add 1 to each row.
    tempRows = tempRows + 1;
    allProps = findobj(view.Properties, 'isVisible', true, ...
        'isTransient', false, 'isReserved', false);
    % If we do not have invalid row, move.
    if isempty(find(tempRows > (length(allProps) - 1), 1))
        % We can move.
        propsToMove = cell(length(rows), 2);
        for i = 1:length(rows)
            propToMove = allProps(rows(i) + 1).Name;        
            rowToMoveAfter = rows(i) + 1;
            if ~isempty(find(rows == rowToMoveAfter))
                rowToMoveAfter = rows(end) + 1;
            end
            propToMoveAfter = allProps(rowToMoveAfter + 1).Name;        
            propsToMove{i,1} = propToMove;
            propsToMove{i,2} = propToMoveAfter;        
        end
        % Move
        view.disableLiveliness;
        vProps = view.Properties;    
        if length(rows) == 1
             vProps = swapProperties(vProps, propsToMove{1}, propsToMove{2});          
        else
            num = length(propsToMove);
            for i = 1:num
                vProps = swapProperties(vProps, char(propsToMove{num-i+1, 1}), ...
                                char(propsToMove{num-i+1, 2}));
            end
        end    
        view.enableLiveliness;
        view.Properties = vProps;
        dlg.selectTableRows('view_columns_table', double(rows+1));
    end
    DAStudio.MEView_cb(dlg, 'doEnableDisableButtons');
end

%
%
%
function doReorderProperties(dlg, view, proposedOrder, sideeffects)
    acceptedOrder = proposedOrder;
    
    % let the accepted order be the proposed order with Name first
    aIndex = strmatch('Name', acceptedOrder, 'exact');
    if isempty(aIndex)
        aIndex = 1;
    else
        if aIndex ~= 1
            acceptedOrder(aIndex) = [];
            acceptedOrder = ['Name'; acceptedOrder];
            aIndex = 1; % account for Name being first column
        end
    end
    view.disableLiveliness;
    % rearrange the current properties list to reflect the accepted columns
    props  = view.Properties;
    for i = 1:length(props)
        prop = props(i);
        if prop.isVisible
            if ~strcmp(prop.Name, acceptedOrder{aIndex})
                pIndex = strmatch(acceptedOrder{aIndex}, get(props, 'Name'), 'exact');
                pObj   = findobj(props, 'Name', acceptedOrder{aIndex});
                
                % remove
                props(pIndex) = [];
                
                % insert
                props = [props(1:i-1); pObj; props(i:end)]; 
            end
            
            aIndex = aIndex + 1;
        end
    end
    view.Properties = props;
    view.enableLiveliness;
        
    if ~view.ViewManager.IsCollapsed
        % update the view manager UI
        dlg.refresh;
    end
end

%
%
function valid = isValidPropertyName(prop)
    %
    % Is this a valid property name?
    % Alpha then alphanumeric, dots, spaces, parenthesis are allowed.
    % 
    valid = ~isempty(regexpi(prop,'^[a-z_][.\(\)\w\s]*$','once'));
end
    
%
% Swap two properties in properties array.
%
function props = swapProperties(vProps, p1, p2)
    viewProperties = get(vProps, 'Name');    
    id1 = strmatch(p1, viewProperties, 'exact');
    id2 = strmatch(p2, viewProperties, 'exact');
    tempProperty = vProps(id1);         
    vProps(id1) = vProps(id2);
    vProps(id2) = tempProperty; 
    props = vProps;
end
    

%
% add property to a view
%
function doAddProperty(view, property, location)

    if ~isempty(view) && ~isempty(property)
        if isempty(location)
            location = 'append';
        end
        for i = 1:length(property)
            % Check for any duplicates
            prop = [];
            if isempty(view.Properties)            
                view.Properties = [];
            else
                propertyIndex = find(strcmpi(get(view.Properties, 'Name'), ...
                    property{i}.Name), 1);
                if ~isempty(propertyIndex)
                    % Property already exists. Just make it visible.
                    prop = view.Properties(propertyIndex);
                end
            end
            if isempty(prop)
                if strcmpi(location, 'append')
                    view.Properties = [view.Properties; property{i}];
                else
                    % Setting properties. Make sure name is first
                    view.Properties = [property{i}; view.Properties];
                    index = find(strcmpi(get(view.Properties, 'Name'), 'Name'));
                    if ~isempty(index) && index ~= 1
                        tempProperty = view.Properties(1);
                        view.Properties(1) = view.Properties(index);
                        view.Properties(index) = tempProperty;
                    end                
                end
            else
                % Just make it visible
                prop.isVisible = true;
            end
        end
    end
end

end