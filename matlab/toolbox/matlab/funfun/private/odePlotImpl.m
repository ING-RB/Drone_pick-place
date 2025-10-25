function status = odePlotImpl(fun,flag,plotname,opts)
% Internal Only - May change in a future release without warning.
% Function to implement plotting updates and callbacks in odeplot,
% odephas2, and odephas3.
% fun is a function that encapsulates the behavior specific to plotting.
%       This changes depending on the value of flag.
% flag is the typical OutputFun flag parameters, either "done", "init", or
%       "". Must be consistent with fun.
% plotname is the name of the calling function. For now, just used to set
%       the appropriate error message qualifier.
% opts contains only SetAxis (optional), which is used by odeplot to set 
%       xlim.

%   Copyright 2023 The MathWorks, Inc.

    arguments
        fun
        flag
        plotname
        opts.SetAxis = []
    end

    persistent TARGET_FIGURE TARGET_AXIS
    
    status = 0;         % Assume stop button wasn't pushed.
    callbackDelay = 1;  % Check Stop button every 1 sec.
    errMessageQualifier = "MATLAB:" + plotname + ":";
    
    % support odeplot(t,y) [v5 syntax]
    if nargin < 3 || isempty(flag)
        flag = '';
    elseif isstring(flag) && isscalar(flag)
        flag = char(flag);
    end
    
    switch(flag)
    
        case ''    % odeplot(t,y,'')
    
            if (isempty(TARGET_FIGURE) || isempty(TARGET_AXIS))
    
                error(message(errMessageQualifier + 'NotCalledWithInit'));
    
            elseif (ishghandle(TARGET_FIGURE) && ishghandle(TARGET_AXIS))  % figure still open
    
                try
                    ud = get(TARGET_FIGURE,'UserData');
                    if ud.stop == 1  % Has stop button been pushed?
                        status = 1;
                    else
                        ud = fun(ud);
                        if datetime("now") - ud.callbackTime < callbackDelay
                            drawnow limitrate;
                        else
                            ud.callbackTime = datetime("now");
                            set(TARGET_FIGURE,'UserData',ud);
                            drawnow;
                        end
                    end
                catch ME
                    error(message(errMessageQualifier + 'ErrorUpdatingWindow', ME.message));
                end
    
            end
    
        case 'init'    % odeplot(tspan,y0,'init')
    
            f = figure(gcf);
            TARGET_FIGURE = f;
            TARGET_AXIS = gca;
            ud = get(f,'UserData');
    
            % Initialize lines
            ud = fun(ud,ishold,TARGET_AXIS);
    
            if ~ishold && ~isempty(opts.SetAxis)
                set(TARGET_AXIS,'XLim',opts.SetAxis);
            end
    
            % The STOP button
            h = findobj(f,'Tag','stop');
            if isempty(h)
                pos = get(0,'DefaultUicontrolPosition');
                pos(1) = pos(1) - 15;
                pos(2) = pos(2) - 15;
                uicontrol( ...
                    'Style','pushbutton', ...
                    'String',getString(message('MATLAB:odeplot:ButtonStop')), ...
                    'Position',pos, ...
                    'Callback',@StopButtonCallback, ...
                    'Tag','stop');
                ud.stop = 0;
            else
                % make sure it's visible
                set(h,'Visible','on');
                % don't change old ud.stop status
                if ~ishold || ~isfield(ud,'stop')
                    ud.stop = 0;
                end
            end
    
            % Set figure data
            ud.callbackTime = datetime("now");
            set(f,'UserData',ud);
    
            % fast update
            drawnow limitrate;
    
        case 'done'    % odeplot([],[],'done')
    
            f = TARGET_FIGURE;
            TARGET_FIGURE = [];
            ta = TARGET_AXIS;
            TARGET_AXIS = [];
    
            if ishghandle(f)
                ud = get(f,'UserData');
                if ishghandle(ta)
                    ud = fun(ud,ta);
                end
                set(f,'UserData',rmfield(ud,{'anim','callbackTime'}));
                if ~ishold
                    set(findobj(f,'Tag','stop'),'Visible','off');
                    if ishghandle(ta)
                        set(ta,'XLimMode','auto');
                    end
                end
            end
    
            % full update
            drawnow;
    
        otherwise
    
            error(message(errMessageQualifier + 'UnrecognizedFlag', flag));
    
    end  % switch flag

end  % odeplot

% --------------------------------------------------------------------------
% Sub-function
%

function StopButtonCallback(~,~)
    ud = get(gcbf,'UserData');
    ud.stop = 1;
    set(gcbf,'UserData',ud);
end  % StopButtonCallback