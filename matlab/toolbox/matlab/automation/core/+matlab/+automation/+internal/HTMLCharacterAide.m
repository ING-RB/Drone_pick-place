classdef HTMLCharacterAide
% This class is undocumented and may change in a future release.

% Copyright 2018-2024 The MathWorks, Inc.
    properties(Access=private,Constant)
        SpecialCharacters = ["<",">","&","'",""""];
        Replacements = ["&lt;","&gt;","&amp;","&#39;","&quot;"];
    end
    
    methods(Static)
        function txt = escape(txt)
            import matlab.automation.internal.HTMLCharacterAide;
            txt = replace(txt,HTMLCharacterAide.SpecialCharacters,...
                HTMLCharacterAide.Replacements);
        end
        
        function txt = unescape(txt)
            import matlab.automation.internal.HTMLCharacterAide;
            txt = replace(txt,HTMLCharacterAide.Replacements,...
                HTMLCharacterAide.SpecialCharacters);
        end
        
        function txt = escapeAllButLinkAndStrongTags(txt)
            import matlab.automation.internal.HTMLCharacterAide;
            tokens = createTokensNotFoundIn(txt,9);
            txt = regexprep(txt,...
                ["<a +href *= *""([^""]*)"" +style *= *""([^""]*)"" *>(.*?)</a>", ...
                "<a +href *= *""([^""]*)"" *>(.*?)</a>", ...
                "<strong>(.*?)</strong>"],...
                [
                tokens(1)+"$1"+tokens(2)+"$2"+tokens(3)+"$3"+tokens(4),...
                tokens(5)+"$1"+tokens(6)+"$2"+tokens(7),...
                tokens(8)+"$1"+tokens(9)]);
            txt = HTMLCharacterAide.escape(txt);
            txt = regexprep(txt,...
                [tokens(1)+"(.*?)"+tokens(2)+"(.*?)"+tokens(3)+"(.*?)"+tokens(4), ...
                tokens(5)+"(.*?)"+tokens(6)+"(.*?)"+tokens(7),...
                tokens(8)+"(.*?)"+tokens(9)],...
                ["<a href=""${matlab.automation.internal.HTMLCharacterAide.unescape($1)}"" style=""${matlab.automation.internal.HTMLCharacterAide.unescape($2)}"">$3</a>", ...
                "<a href=""${matlab.automation.internal.HTMLCharacterAide.unescape($1)}"">$2</a>", ...
                "<strong>$1</strong>"]);
        end
    end
end

function tokens = createTokensNotFoundIn(txt,numOfTokens)
token = "TOKEN";
while contains(txt,token)
    token = matlab.lang.internal.uuid();
end
tokens = token + (1:numOfTokens);
end
