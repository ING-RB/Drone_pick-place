classdef DebugUtils < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2024 The MathWorks, Inc.

    methods(Static)
        function naninfBreakpoint = disableNanInfBreakpoint()
            % Disable the naninf breakpoint if it is set.  This is done
            % because if the user does a 'dbstop if naninf', we don't want
            % it to be hit during the background running code in the
            % workspace browser or variable editor.  Returns a logical
            % which is whether the naninf breakpoint was set by the user.
            try
                b = dbstatus;
                naninfBreakpoint = false;
                for i = 1:length(b)
                    if isequal(b(i).cond, "naninf")
                        dbclear("if", "naninf");
                        naninfBreakpoint = true;
                        break;
                    end
                end
            catch
                % Ignore any errors.  This can happen when this is called on
                % the background thread, for example, where breakpoints are
                % not supported.
                naninfBreakpoint = false;
            end
        end

        function reEnableNanInfBreakpoint(naninfBreakpoint)
            % Reenable the naninf breakpoint if it was previously set.
            if naninfBreakpoint
                dbstop("if", "naninf");
            end
        end
    end
end
