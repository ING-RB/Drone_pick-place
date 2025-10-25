classdef (Hidden) Display < handle
%   This class is for internal use only. It may be removed in the future.
%DISPLAY Iteration display for the filter tuner
    
%   Copyright 2020 The MathWorks, Inc.
    
    properties (Constant)
        LeadingSpace = 4;
        BetweenColumnSpaces = 4;
    end
    
    properties
        Silent = false;
        ParameterColumnWidth
        IterationColumnWidth
    end
    methods
        function obj = Display(maxiters, params2tune, verbosity)
            % Construct the Display object and setup maximum field widths
            maxiterlen = strlength(sprintf('%d', maxiters));
            maxiterlen = max(maxiterlen, strlength(getIterationString()));
            
            maxparamlen = max(strlength(params2tune));
            maxparamlen = max(maxparamlen, strlength(getParameterString()));
            
            obj.ParameterColumnWidth = maxparamlen;
            obj.IterationColumnWidth = maxiterlen;
            obj.Silent = (verbosity == ...
                fusion.internal.tuner.DisplayChoices.none);
            printHeader(obj);
        end
        
        function printHeader(obj)
            % Prints the header rows.
            if ~obj.Silent
                obj.printHeaderLine(getIterationString(), ...
                    getParameterString(), getMetricString());
                obj.printHeaderLine("_________", "_________", "______");
            end
        end
        function printRow(obj, iter, param, metric)
            if ~obj.Silent
                mstr = matlab.internal.display.numericDisplay(metric);
                b = string(blanks(obj.BetweenColumnSpaces));
                s = string(blanks(obj.LeadingSpace)) + ...
                    sprintf('%-*d', obj.IterationColumnWidth, iter) + ...
                    b + ...
                    sprintf('%-*s', obj.ParameterColumnWidth, param) + ...
                    b + ...
                    mstr + ...
                    newline;
                fprintf(s);
            end
        end
    end
    methods (Access = protected)
        function printHeaderLine(obj, itertxt, paramtxt, metrictxt)
            % Prints a single bold line of the header
            b = string(blanks(obj.BetweenColumnSpaces));
            s = string(blanks(obj.LeadingSpace)) + ...
                sprintf('%-*s', obj.IterationColumnWidth, itertxt) + ...
                b + ...
                sprintf('%-*s', obj.ParameterColumnWidth, paramtxt) + ...
                b + ...
                sprintf('%-6s', metrictxt) + ...
                newline;
            fprintf(strongBegin + s + strongEnd);
        end
    end
end

function s = getIterationString
s = getString(message('shared_positioning:tuner:Iteration'));
end
function s = getParameterString
s = getString(message('shared_positioning:tuner:Parameter'));
end
function s = getMetricString
s = getString(message('shared_positioning:tuner:Metric'));
end
function s = strongBegin
s = getString(message('MATLAB:table:localizedStrings:StrongBegin'));
end
function s = strongEnd
s = getString(message('MATLAB:table:localizedStrings:StrongEnd'));
end
