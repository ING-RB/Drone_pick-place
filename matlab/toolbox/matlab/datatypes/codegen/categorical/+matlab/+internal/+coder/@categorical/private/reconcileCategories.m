function [acodes,bcodes,prototype] = reconcileCategories(a,b,requireOrdinal) %#codegen
%RECONCILECATEGORIES Utility for logical comparison of categorical arrays.

%   Copyright 2018-2020 The MathWorks, Inc.

compareCategoricalToCategorical = isa(a,'categorical') && isa(b,'categorical');
compareCategoricalToText = matlab.internal.coder.datatypes.isScalarText(b) || matlab.internal.coder.datatypes.isCharStrings(b);
compareTextToCategorical = matlab.internal.coder.datatypes.isScalarText(a) || matlab.internal.coder.datatypes.isCharStrings(a);
validComparison = compareCategoricalToCategorical || compareCategoricalToText || compareTextToCategorical;
coder.internal.assert(validComparison,'MATLAB:categorical:InvalidComparisonTypes',class(a),class(b));

if compareCategoricalToCategorical
    coder.internal.errorIf(requireOrdinal && (~a.isOrdinal || ~b.isOrdinal), 'MATLAB:categorical:NotOrdinal');
    coder.internal.errorIf(a.isOrdinal ~= b.isOrdinal, 'MATLAB:categorical:OrdinalMismatchComparison');
    coder.internal.errorIf(requireOrdinal && length(a.categoryNames) ~= length(b.categoryNames),'MATLAB:categorical:InvalidOrdinalComparison');
    
    anames = a.categoryNames;
    if coder.internal.isConst(size(anames))
        % Ensure anames is homogeneous
        coder.varsize('anames',[],[0 0]);
    end
    
    bnames = b.categoryNames;
    if coder.internal.isConst(size(bnames))
        % Ensure bnames is homogeneous
        coder.varsize('bnames',[],[0 0]);
    end
    
    if coder.internal.isConst(a.numCategoriesUpperBound) && coder.internal.isConst(b.numCategoriesUpperBound)
        numcats = coder.const(a.numCategoriesUpperBound + b.numCategoriesUpperBound); % this should be constant
    else
        numcats = coder.const(categorical.maxNumCategories);
    end
    
    % Type of must be constant for acodes and bcodes since isequal can only
    % be checked at runtime. Thus, acodes and bcodes will be cast up based
    % on total numcats.
    if a.isOrdinal && ~isequal(anames,bnames) % && b.isOrdinal
        coder.internal.error('MATLAB:categorical:InvalidOrdinalComparison');
    else
        [bcodes,~] = categorical.convertCodes(b.codes,bnames,anames,a.isProtected,b.isProtected,numcats);
        acodes = cast(a.codes,'like',bcodes); % bcodes is always a higher or equivalent integer class as acodes
    end
    prototype = a; % preserve subclass
    
elseif compareCategoricalToText
    coder.internal.errorIf(requireOrdinal && ~a.isOrdinal, 'MATLAB:categorical:NotOrdinal');
    
    acodes = a.codes;
    anames = a.categoryNames;
    if coder.internal.isConst(size(anames))
        % Ensure anames is homogeneous
        coder.varsize('anames',[],[0 0]);
    end
    
    if coder.internal.isConst(a.numCategoriesUpperBound)
        numcats = coder.const(a.numCategoriesUpperBound); 
    else
        numcats = coder.const(categorical.maxNumCategories);
    end
    
    [ib,ub] = a.strings2codes(b);
    [bcodes,~] = categorical.convertCodes(ib,ub,anames,a.isProtected,false, numcats);
    acodes = cast(acodes,'like',bcodes); % bcodes is always a higher or equivalent integer class as acodes
    
    prototype = a; % preserve subclass
    
elseif compareTextToCategorical
    coder.internal.errorIf(requireOrdinal && ~b.isOrdinal, 'MATLAB:categorical:NotOrdinal');
    
    bcodes = b.codes;
    bnames = b.categoryNames;
    if coder.internal.isConst(size(bnames))
        % Ensure bnames is homogeneous
        coder.varsize('bnames',[],[0 0]);
    end
    
    if coder.internal.isConst(b.numCategoriesUpperBound)
        numcats = coder.const(b.numCategoriesUpperBound); 
    else
        numcats = coder.const(categorical.maxNumCategories);
    end
    
    [ia,ua] = b.strings2codes(a);
    [acodes,~] = categorical.convertCodes(ia,ua,bnames,b.isProtected,false,numcats);
    bcodes = cast(bcodes,'like',acodes); % acodes is always a higher or equivalent integer class as bcodes

    prototype = b; % preserve subclass
end
