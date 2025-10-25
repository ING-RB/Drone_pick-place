classdef DatePickerInteractor < matlab.uiautomation.internal.interactors.AbstractComponentInteractor & ...
                                matlab.uiautomation.internal.interactors.mixin.ContextMenuable
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2018-2019 The MathWorks, Inc.
    
    methods
        
        function uitype(actor, date)
            
            narginchk(2, 2);
            
            datepicker = actor.Component;
            if any(string({datepicker.Editable, datepicker.Enable}) == matlab.lang.OnOffSwitchState.off)
                error(message( ...
                    'MATLAB:uiautomation:Driver:MustBeEditableAndEnabled'));
            end
            
            validateattributes(date, {'datetime'}, {'scalar'});
            % check for finiteness but forgive NaT's, which are not finite
            if ~isnat(date)
                validateattributes(date, {'datetime'}, {'finite'});
            end
            
            % formatting depends on locale - let the client handle that
            actor.Dispatcher.dispatch(datepicker, 'uitype', ...
                'Year', date.Year, ...
                'Month', date.Month, ...
                'Day', date.Day);
        end
        
    end
end