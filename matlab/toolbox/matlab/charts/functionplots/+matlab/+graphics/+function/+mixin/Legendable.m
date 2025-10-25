classdef Legendable < matlab.graphics.mixin.Legendable
    % This class is undocumented and may change in a future release.

    % Copyright 2022 The MathWorks, Inc.

    properties(Access=protected,Transient)
        DisplayName_I_ByInterpreter = struct;
    end

    methods(Access={?matlab.graphics.mixin.Legendable, ...
            ?matlab.graphics.illustration.Legend, ...
            ?matlab.graphics.illustration.legend.LegendEntry, ...
            ?matlab.unittest.TestCase})
        function displayName = getDisplayNameForInterpreter(hObj, interpreter)
            if hObj.DisplayNameMode == "auto" && ...
                isfield(hObj.DisplayName_I_ByInterpreter, interpreter)
                displayName = hObj.DisplayName_I_ByInterpreter.(interpreter);
                return;
            end
            displayName = string(hObj.DisplayName_I);
            if hObj.DisplayNameMode == "auto" && interpreter == "latex"
                % For the LaTeX interpreter, use math mode.
                displayName = "$" + displayName + "$";
            end
        end
    end

    methods(Access={?matlab.graphics.mixin.Legendable, ...
            ?matlab.unittest.TestCase})
        function s=displayNames(~,fn,i)
            % convert function to strings suitable for interpreter 'tex', 'latex', and 'none'
            s = struct;
            if isa(fn,'function_handle')
                fn = regexprep(char(fn),'^@(\(.*?\))?\s*','');
            end
            if nargin > 2 && i > 0
                if isa(fn,'sym') && numel(fn) >= i
                    fn = fn(i);
                elseif regexp(string(fn),"^\s*\[.*\]\s*$")
                    inner = regexprep(string(fn),"^\s*\[(.*)\]\s*$","$1");
                    fineSplit = split(inner,",");
                    nesting = count(fineSplit,["(","{","["]) - count(fineSplit,[")","}","]"]);
                    for k=numel(fineSplit):-1:2
                        if nesting(k) < 0
                            fineSplit(k-1) = fineSplit(k-1)+","+fineSplit(k);
                            fineSplit(k) = [];
                            nesting(k-1) = nesting(k-1)+nesting(k);
                            nesting(k) = [];
                        end
                    end
                    if numel(fineSplit) >= i
                        fn = fineSplit(i);
                    end
                end
            end
            s.none = replace(string(fn),[".*" ".^" "./"],["*" "^" "/"]);
            s.tex = texlabel(fn);
            if isa(fn,'sym')
                s.latex = "$"+ latex(fn) + "$";
            else
                s.latex = "$"+ regexprep(s.tex,"\{([a-z0-9]{2,})\}","\\mathrm{$1}") + "$";
            end
        end
    end
end
