classdef referenceHitIndex
    properties
        index              (1,1) double  = 0;
        isCaseMatch        (1,1) logical = false;
        isParent           (1,1) logical = false;
        isProductQualified (1,1) logical = false;
        isWrongBook        (1,1) logical = false;
        isUnderqualified   (1,1) logical = false;
        isFunction         (1,1) logical = false;
        isConstructor      (1,1) logical = false;
        isCheckedOut       (1,1) logical = false;

        item matlab.internal.reference.api.ReferenceData = matlab.internal.reference.api.ReferenceData.empty();
    end

    methods
        function tf = logical(rhi)
            tf = rhi.index > 0;
        end

        function tf = gt(lhs, rhs)
            if isempty(rhs.item)
                tf = true;
            elseif rhs.isWrongBook ~= lhs.isWrongBook
                tf = rhs.isWrongBook;
            elseif rhs.isParent ~= lhs.isParent
                tf = rhs.isParent;
            elseif rhs.isProductQualified ~= lhs.isProductQualified
                tf = rhs.isProductQualified;
            elseif rhs.isCaseMatch ~= lhs.isCaseMatch
                tf = lhs.isCaseMatch;
            elseif lhs.item.DeprecationStatus ~= rhs.item.DeprecationStatus
                tf = lhs.item.DeprecationStatus < rhs.item.DeprecationStatus;
            elseif rhs.isUnderqualified ~= lhs.isUnderqualified
                tf = rhs.isUnderqualified;
            elseif rhs.isFunction ~= lhs.isFunction
                tf = lhs.isFunction;
            elseif lhs.isCheckedOut ~= rhs.isCheckedOut
                tf = lhs.isCheckedOut;
            else
                lhsHasTime = lhs.item.IntroducedIn ~= "";
                if rhs.item.IntroducedIn ~= ""
                    tf = lhsHasTime && upper(lhs.item.IntroducedIn) < upper(rhs.item.IntroducedIn);
                else
                    tf = lhsHasTime;
                end
            end
        end
    end
end

%   Copyright 2022-2024 The MathWorks, Inc.
