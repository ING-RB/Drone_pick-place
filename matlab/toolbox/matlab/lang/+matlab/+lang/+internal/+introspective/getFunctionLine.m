function [functionNames, functionSplit] = getFunctionLine(fullText, functionName, exact)
%

%   Copyright 2018-2020 The MathWorks, Inc.

    if exact
        count = 'once';
    else
        count = 'all';
    end
    [functionNames, functionSplit] = regexp(fullText, functionPattern(functionName, exact), 'dotexceptnewline', 'lineanchors', 'names', 'split', count);
end

function i = id
    alpha = "[a-zA-Z]";
    i = alpha + "\w*";
end

function o = optional(p)
    o = "(?:" + p + ")?";
end

function k = kleene(p)
    k = "(?:" + p + ")*";
end

function w = white
    w = kleene("[ \t]");
end

function e = either(p1, p2)
    e = "(?:" + p1 + "|" + p2 + ")";
end

function c = capture(name, p)
    c = "(?<" + name + ">" + p + ")";
end

function list = idList(id, separator)
    list = white + optional(id + white + kleene(separator + white + id + white));
end

function p = functionPattern(functionName, exact)
    bracketed = "\[" + idList(id, "[, \t]") + "\]";
    parenthesized = "\(" + idList(either(id, "~"), ",") + "\)";
    lhs = optional(either(bracketed, id) + white + "=" + white);
    rhs = optional(parenthesized + white);
    if functionName == ""
        functionName = id;
    elseif ~exact
        functionName = "(?i:" + functionName + ")";
    end
    p = "^" + white + "(?-i:function)\>[ \t]*" + capture("lhs", lhs) + capture("functionName", functionName) + white + capture("rhs", rhs) + either("[,;%].*", "\r?$");
end
