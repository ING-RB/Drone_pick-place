function action_performed = managed_setparams(params)
    if ~iscell(params)
        action_performed = 'There is no parameters to manage.';
        return;
    end

    ret_value = '';
    for i= 1:length(params)
        if iscell(params{i}) && (length(params{i}) > 2)
            old_val = get_param(params{i}{1}, params{i}{2});
            out_str = message('SL_SERVICES:utils:PREVIOUS_PARAM_VALUE', params{i}{2}, params{i}{1}, old_val, params{i}{3}).getString();
            ret_value = [ret_value out_str];
            set_param(params{i}{1}, params{i}{2}, params{i}{3});
        end
    end

    if isequal(length(dbstack()), 1) %managed_setparams was called from CL
        disp([message('SL_SERVICES:utils:FixedString').getString() ':'  ret_value]);
    end
    action_performed = ret_value;
end
