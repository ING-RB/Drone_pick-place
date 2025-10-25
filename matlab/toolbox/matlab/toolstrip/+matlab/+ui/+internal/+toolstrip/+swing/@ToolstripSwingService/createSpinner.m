function createSpinner(this, widget_node)
    %% get widget peer node id
    widget_id = char(widget_node.getId());
    %% create swing widget
    jh = javaObjectEDT('com.mathworks.toolstrip.components.TSSpinner');
    %% register widget (key: widget_id, value: swing handle)
    this.Registry.register('Widget', widget_id, jh);
    %% get action peer node
    action_node = getActionNodeFromWidgetNode(this, widget_node);
    %% initialize swing component properties
    % tag
    value = widget_node.getProperty('tag');
    jh.setName(value);
    % description
    value = action_node.getProperty('description');
    this.setSwingTooltip(jh,value);
    % enabled
    value = action_node.getProperty('enabled');
    jh.setEnabled(value);
    % value
    value1 = action_node.getProperty('value');
    % minimum
    value2 = action_node.getProperty('minimum');
    % maximum
    value3 = action_node.getProperty('maximum');
    % minorStepSize
    value4 = action_node.getProperty('minorStepSize');
    % numberFormat
    numberformat = action_node.getProperty('numberFormat');
    if strcmpi(numberformat,'integer')
        % set model with integer
        model = javaObjectEDT('javax.swing.SpinnerNumberModel',java.lang.Integer(value1),java.lang.Integer(value2),java.lang.Integer(value3),java.lang.Integer(value4));
        jh.setModel(model);
    else
        % set model with double precision
        model = javaObjectEDT('javax.swing.SpinnerNumberModel',value1,value2,value3,value4);
        jh.setModel(model);
        % set decimal format
        decimalformat = action_node.getProperty('format');
        editor = getEditor(jh);
        format = getFormat(editor);
        swing_format = localConvertToDecimalFormat(decimalformat);
        format.applyPattern(swing_format);
        % update editor display
        txt = editor.getTextField();
        newstr = localNum2Str(value1,decimalformat);
        javaMethodEDT('setText',txt,newstr);
    end
    %% register listeners to Swing driven events
    action_id = char(action_node.getId());
    fcn = {@valueChangedCallback, this, action_id};
    registerSwingListener(this, widget_node, jh, 'StateChanged', fcn);
    %% register listeners to MCOS driven events
    fcn = {@propertySetCallback, this, widget_id};
    registerPeerNodeListener(this, widget_node, action_node, fcn);
end

function valueChangedCallback(src, ~, this, action_id)
    % When a spinner arrow is clicked for the first time, two state changed
    % events are fired.  that is the default behavior for JSpinner.
    action_node = getActionNodeFromId(this, action_id);
    if ~isempty(action_node)
        % Update the action node value
        oldvalue = action_node.getProperty('value');
        newvalue = src.getValue();
        if oldvalue ~= newvalue
            action_node.setProperty('value',newvalue);
            % Dispatch a ValueChanged event to notify any listeners
            eventdata = java.util.HashMap;
            eventdata.put('eventType','ValueChanged');
            eventdata.put('Value',newvalue);
            action_node.dispatchPeerEvent('peerEvent',action_node,eventdata);
        end
    end
end

function propertySetCallback(~, data, this, widget_id)
    % check originator
    originator = data.getOriginator();
    % set property value ONLY If it is a MCOS driven event
    if isa(originator, 'java.util.HashMap') && strcmp(originator.get('source'),'MCOS')
        % get data
        hashmap = data.getData();
        structure = matlab.ui.internal.toolstrip.base.Utility.convertFromHashmapToStructure(hashmap);
        % get swing widget
        jh = this.Registry.getWidgetById(widget_id);    
        mdl = jh.getModel();
        isDouble = isa(mdl.getNumber(),'java.lang.Double');
        value = structure.newValue;
        % set swing property
        switch structure.key
            case 'description'
                this.setSwingTooltip(jh,value);
            case 'enabled'
                jh.setEnabled(value);
            case 'minimum'
                if isDouble
                    javaMethodEDT('setMinimum',mdl,java.lang.Double(value));
                else
                    javaMethodEDT('setMinimum',mdl,java.lang.Integer(value));
                end
            case 'maximum'
                if isDouble
                    javaMethodEDT('setMaximum',mdl,java.lang.Double(value));                
                else
                    javaMethodEDT('setMaximum',mdl,java.lang.Integer(value));                
                end
            case 'value'
                if isDouble
                    this.setValueWithoutFiringEvent('spinner', mdl, java.lang.Double(value));
                    widget_node = getWidgetNodeFromId(this, widget_id);
                    action_node = getActionNodeFromWidgetNode(this, widget_node);
                    decimalformat = action_node.getProperty('format');
                    txt = jh.getEditor().getTextField();
                    newstr = localNum2Str(value,decimalformat);
                    javaMethodEDT('setText',txt,newstr);
                else
                    this.setValueWithoutFiringEvent('spinner', mdl, java.lang.Integer(value));
                    txt = jh.getEditor().getTextField();
                    javaMethodEDT('setText',txt,java.lang.String(num2str(value)));                    
                end
            case 'minorStepSize'
                if isDouble
                    javaMethodEDT('setStepSize',mdl,java.lang.Double(value));
                else
                    javaMethodEDT('setStepSize',mdl,java.lang.Integer(value));
                end
            case 'tag'
                jh.setName(value);
        end
    end
end

function swing_format = localConvertToDecimalFormat(ml_format)
    % ml_format should be %0.nf or %0.ne where n is precision
    str = ml_format(4:end);
    n = str2double(str(1:end-1));
    if strcmpi(ml_format(end),'e')
        notation = 'E0';        
    else
        notation = '';
    end
    tail = [repmat('#',[1 n]) notation];
    swing_format = ['0.' tail];
end

function newstr = localNum2Str(value,ml_format)
    % ml_format should be %0.nf or %0.ne where n is precision
    str = num2str(value,ml_format);
    if strcmpi(ml_format(end),'e')
        % scientific display
        array = strsplit(str,'e');
        % modify exponential term for swing display 
        expterm = num2str(str2double(array{2}));
        % get rid off trailing zeros
        array_dot = strsplit(array{1},'.');
        if length(array_dot)==2
            % has decimal point
            middle = array_dot{2};
            for ct=length(middle):-1:1
                if strcmp(middle(ct),'0')
                    middle(ct)='';
                else
                    break;
                end
            end
            if isempty(middle)
                newstr = [array_dot{1} 'E' expterm];
            else
                newstr = [array_dot{1} '.' middle 'E' expterm];
            end
        else
            % no decimal point (i.e. integer)
            newstr = [array_dot{1} 'E' expterm];
        end
    else
        % fixed-point display
        array_dot = strsplit(str,'.');
        % get rid off trailing zeros
        if length(array_dot)==2
            % has decimal point
            middle = array_dot{2};
            for ct=length(middle):-1:1
                if strcmp(middle(ct),'0')
                    middle(ct)='';
                else
                    break
                end
            end
            if isempty(middle)
                newstr = array_dot{1};
            else
                newstr = [array_dot{1} '.' middle];
            end
        else
            % no decimal point (i.e. integer)
            newstr = array_dot{1};
        end
    end
    newstr = java.lang.String(newstr);
end
