function property_inspector_hilite( objects, on)
%

% Copyright 2004 The MathWorks, Inc. 
 
    styler = [];
    rule = '';
    
    size = length(objects);
    handle = -1;
    isStateflow = false;
    for i = 1:size
        obj = objects{i};
        if isa(obj, 'Simulink.Block')
                rule = 'EditBlock';
                handle = obj.Handle;
        elseif isa(obj, 'Simulink.Line')
                rule = 'EditLine';
                handle = obj.getSourcePort.Line;
        elseif isa(obj, 'Stateflow.State')
                rule = 'EditState';
                handle = obj.Id;
                isStateflow = true;
        elseif isa(obj, 'Stateflow.Transition')
                rule = 'EditTransition';
                handle = obj.Id;
                isStateflow = true;
        end
        
        if ~isempty(rule)
            styler = getPropertyStyler(isStateflow);
        end
        
        if ~isempty(styler)
            if on
                styler.applyClass(handle, rule);
            else
                styler.removeClass(handle, rule);
            end
        end
    end % end for
end % end hilite

function styler = getPropertyStyler( stateflow )

stylerName = 'PropertyInspector.EditStyler';
styler = diagram.style.getStyler(stylerName);

        % edit style
        editStyle = diagram.style.Style;
        editStyle.set('FillStyle',   'Solid');
        editStyle.set('FillColor',   [0.1 0.8 0.8 1.0]);
        editStyle.set('StrokeColor',   [0.0 0.0 1.0 1.0]);
        editStyle.set('StrokeWidth',   1.0);
        editStyle.set('StrokeStyle',   'SolidLine');

    % if styler doesn't exists create one
    if(isempty(styler))
        diagram.style.createStyler(stylerName);
        styler = diagram.style.getStyler(stylerName);
        
        % add the edit block rule
        styler.addRule(editStyle, diagram.style.ClassSelector('EditBlock', 'simulink.Block'));
        % add the edit line rule
        styler.addRule(editStyle, diagram.style.ClassSelector('EditLine', 'simulink.Line'));
    end

    if( stateflow )
        % add the edit state rule
        styler.addRule(editStyle, diagram.style.ClassSelector('EditState', 'stateflow.State'));
        % add the edit line rule
        styler.addRule(editStyle, diagram.style.ClassSelector('EditTransition', 'stateflow.Transition'));
    end


%         % context style
%         contextStyle = diagram.style.Style;
%         contextStyle.set('FillStyle',   'Solid');
%         contextStyle.set('FillColor',   [0.8 0.9 0.7 0.5]);
%         contextStyle.set('StrokeColor',   [0.0 0.0 1.0 1.0]);
%         contextStyle.set('StrokeWidth',   1.0);
%         contextStyle.set('StrokeStyle',   'SolidLine');
% 
% 
%         % add a rule that applies orange color on any element that have test Class (Class here is analogus to CSS Class)
%         styler.addRule(contextStyle, diagram.style.ClassSelector('Context'));
end %end getPropertyStyler

