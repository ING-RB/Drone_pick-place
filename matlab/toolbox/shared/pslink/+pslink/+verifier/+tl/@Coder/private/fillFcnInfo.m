function fillFcnInfo(self, execMap)

%
% Copyright 2012 The MathWorks, Inc.
%

% Get the keys as a matrix, remove the key==-inf and sort
keys = execMap.keys();
keys = [keys{:}];
keys(keys==-inf) = [];
keys = sort(keys);

% Init fct
if execMap.isKey(-inf)
    self.fcnInfo.init = pslink.verifier.Coder.createFcnInfoStruct();
    val = execMap(-inf);
    self.fcnInfo.init.fcn = val{1};
    self.fcnInfo.init.var = val{2};
end

% Step fct
for ii = 1:numel(keys)
    if isempty(self.fcnInfo.step)
        self.fcnInfo.step = pslink.verifier.Coder.createFcnInfoStruct();
    else
        self.fcnInfo.step(end+1) = pslink.verifier.Coder.createFcnInfoStruct();
    end
    val = execMap(keys(ii));
    self.fcnInfo.step(end).fcn = val{1};
    self.fcnInfo.step(end).var = val{2};
end

% Term fct
if ~isempty(self.codeInfo.term)
    self.fcnInfo.term = pslink.verifier.Coder.createFcnInfoStruct();
    self.fcnInfo.term.fcn = {nGetFctName(self.codeInfo.term(1).fcn)};
end

%--------------------------------------------------------------------------
    function fctName = nGetFctName(hFct)
        fctName = dsdd('GetAttribute', hFct, 'name');
    end

end