function [method,methodPrefix,isFcnHandle] = groupMethod2FcnHandle(method,eid,dim)
%GROUPMETHOD2FCNHANDLE Convert a method input from groupsummary, pivot, or
%   summary to the corresponding function handle
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2022-2024 The MathWorks, Inc.

if nargin < 3
    dim = 1;
end
isFcnHandle = false;

isforpivot = isequal(eid,'pivot');
isforsummary = isequal(eid,'summary');
isforgroupsummary = ~(isforpivot || isforsummary);

if isforsummary
    methodPrefixes = ["NumUnique" "NumMissing" "NumNonzero" "Mean" "Median" ...
        "Mode" "Var" "Std" "Min" "Max" "Range" "Sum"];
else
    methodPrefixes = ["numunique" "nummissing" "nnz" "mean" "median" ...
        "mode" "var" "std" "min" "max" "range" "sum"];
end

if ischar(method) || isstring(method)
    if strncmpi(method,"numunique",4)
        method = @(x) numunique(x(~ismissing(x)));
        methodPrefix = methodPrefixes(1);
    elseif strncmpi(method,"nummissing",4)
        method = @(x) sum(ismissing(x),dim);
        methodPrefix = methodPrefixes(2);
    elseif strncmpi(method,"nnz",2)
        method = @(x) nnz(x(~ismissing(x)));
        methodPrefix = methodPrefixes(3);
    elseif strncmpi(method,"mean",3)
        method = @(x) mean(x,dim,'omitnan');
        methodPrefix = methodPrefixes(4);
    elseif strncmpi(method,"median",3)
        method = @(x) median(x,dim,'omitnan');
        methodPrefix = methodPrefixes(5);
    elseif (~isforgroupsummary && strncmpi(method,"mode",2)) ||...
            (isforgroupsummary && strncmpi(method,"mode",3))
        method = @(x) mode(x,dim);
        methodPrefix = methodPrefixes(6);
    elseif strncmpi(method,"var",1)
        method = @(x) var(x,0,dim,'omitnan');
        methodPrefix = methodPrefixes(7);
    elseif strncmpi(method,"std",2)
        method = @(x) std(x,0,dim,'omitnan');
        methodPrefix = methodPrefixes(8);
    elseif (~isforgroupsummary && strncmpi(method,"min",2)) ||...
            (isforgroupsummary && strncmpi(method,"min",3))
        method = @(x) min(x,[],dim,'omitnan');
        methodPrefix = methodPrefixes(9);
    elseif strncmpi(method,"max",2)
        method = @(x) max(x,[],dim,'omitnan');
        methodPrefix = methodPrefixes(10);
    elseif strncmpi(method,"range",1)
        method = @(x) unsignedRange(x,dim);
        methodPrefix = methodPrefixes(11);
    elseif strncmpi(method,"sum",2)
        method = @(x) sum(x,dim,'omitnan');
        methodPrefix = methodPrefixes(12);
    elseif isforpivot && strncmpi(method,'count',1)
        method = [];
        methodPrefix = "count";
    elseif isforpivot && strncmpi(method,'percentage',1)
        method = [];
        methodPrefix = "percentage";
    elseif isforpivot && strncmpi(method,"none",2)
        method = @noaggregation;
        methodPrefix = "none";
    elseif isforsummary && strncmpi(method,'q1',2)
        method = @(x) prctile(x,25,dim);
        methodPrefix = "Q1";
    elseif isforsummary && strncmpi(method,"q3",2)
        method = @(x) prctile(x,75,dim);
        methodPrefix = "Q3";
    elseif isforsummary && strncmpi(method,"true",1)
        method = @(x) sum(x,dim);
        methodPrefix = "True";
    elseif isforsummary && strncmpi(method,"false",1)
        method = @(x) sum(~x,dim);
        methodPrefix = "False";
    else
        error(message("MATLAB:" + eid + ":InvalidMethodOption"));
    end
elseif isa(method,"function_handle")
    if isforsummary
        methodPrefix = string(func2str(method));
        if startsWith(methodPrefix,"@")
            methodPrefix = "fun";
        end
        isFcnHandle = true;
    else
        methodPrefix = "fun";
    end
else
    error(message("MATLAB:" + eid + ":InvalidMethodOption"));
end

%--------------------------------------------------------------------------
function R = unsignedRange(x,dim)
% Compute the range and if the input is a signed integer then return range
% as an unsigned integer value.
a = max(x,[],dim,'omitnan');
b = min(x,[],dim,'omitnan');
xClass = class(x);
if isinteger(x) && strncmp("i",xClass,1)
    if sign(a) == sign(b)
        R = cast(a - b, "u" + xClass);
    else % a is always greater than b, so a > 0, b < 0
        R = cast(a, "u" + xClass) + cast(-b, "u" + xClass);
        if b == intmin(xClass)
            R = R + 1;
        end
    end
else
    R = a - b;
end

function x = noaggregation(x)
if size(x,1) > 1
    % pivot problem requires aggregation
    error(message("MATLAB:pivot:NoAggregationWithNonscalarGroups"));
end
