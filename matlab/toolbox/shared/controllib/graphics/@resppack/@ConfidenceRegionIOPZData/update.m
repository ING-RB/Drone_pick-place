function update(this,r)
%UPDATE  Data update method @ConfidenceRegionIOPZData class.

%   Author(s): Craig Buhr
%   Copyright 1986-2015 The MathWorks, Inc.

%  m = r.DataSrc.getModelData;
% [CovZ, CovP] = covZPK(m);
% [Z, P] = zpkdata(zpk(r.DataSrc.Model));

if ~isempty(this.Data), return; end
idxModel = find(r.Data==this.Parent);
[Z,P,~,~,CovZ,CovP] = zpkdata(r.DataSrc.Model(:,:,idxModel));

if ~isempty(CovZ) && ~isempty(CovP)
    CovP = cellfun(@(x) (this.NumSD)^2*x, CovP,'UniformOutput',false);
    CovZ = cellfun(@(x) (this.NumSD)^2*x, CovZ,'UniformOutput',false);
    
    % Struct Data.Poles     {ny,nu} [npoles-by-1]
    %            .Zeros     {ny,nu} [nzeros-by-1]
    %            .CovPoles  {ny,nu} [npoles-by-2-by-2]
    %            .CovZeros  {ny,nu} [nzeros-by-2-by-2]
    this.Data = struct(...
        'Poles', {P},...
        'Zeros', {Z}, ...
        'CovPoles', {CovP}, ...
        'CovZeros', {CovZ});
end

this.TimeUnits = this.Parent.TimeUnits;
