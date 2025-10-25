function kernelInfo = kernelinfo(errPrefix, ftype, kernelname, allowedFcns, fcnArgName)
%[kernel,iscdf,kernelcutoff,kernelname,ftype] 
%KERNELINFO Obtain kernel information from name.

% Note: other functions assume that kernelname and kernelcutoff outputs
% depend only on kernelname and not on ftype.

%   Copyright 2008-2023 The MathWorks, Inc.
if nargin < 5
    % Different functions document the function argument name differently
    fcnArgName = 'Function';
end

% Kernel can be the name of a function local to here, or an external function
% Kernel numbers are used below:
%              1        2               3                4             5       6
kernelnames = {'normal' 'epanechinikov' 'epanechnikov'  'parabolic'   'box'    'triangle'};
kernelhndls = {@normal  @epanechnikov   @epanechnikov   @epanechnikov  @box     @triangle};
cdfhndls    = {@cdf_nl  @cdf_ep         @cdf_ep         @cdf_ep        @cdf_bx  @cdf_tr};
kernelcuts  = [4        sqrt(5)         sqrt(5)         sqrt(5)        sqrt(3)  sqrt(6)];

% Check function type
ftype = char(validatestring(ftype,allowedFcns,'',fcnArgName));
kernelname = convertStringsToChars(kernelname);

% Set a flag indicating we are to compute the cdf; later on
% we may transform to another function that is a transformation
% of the cdf
iscdf = isequal(ftype,'cdf') | isequal(ftype,'survivor') ...
    | isequal(ftype,'cumhazard');
kernel = kernelname;
if isempty(kernelname)
    if iscdf
        kernel = cdfhndls{1};
    else
        kernel = kernelhndls{1};
    end
    kernelname = kernelnames{1};
    kernelcutoff = kernelcuts(1);
elseif ischar(kernelname)
    % If this is an abbreviation of our own methods, expand the name now.
    % If the string matches the start of both variants of the Epanechnikov
    % spelling, that is not an error so pretend it matches just one.
    knum = find(strncmpi(kernelname, kernelnames, length(kernelname)));
    if all(ismember(2:3,knum))   % kernel number used here
        knum(knum==3) = [];
    end
    if isscalar(knum)
        if iscdf
            kernel = cdfhndls{knum};
        else
            kernel = kernelhndls{knum};
        end
        kernelcutoff = kernelcuts(knum);
        kernelname = kernelnames{knum};
    else % custom kernel specified by name
        if isequal(ftype,'icdf')
            % Will only ever hit this branch with SMLT license, which comes
            % with this error
            error(message('stats:ksdensity:IcdfNotAllowed'));
        end
        kernelcutoff = Inf;
    end
elseif (isa(kernelname,'function_handle') || isa(kernelname,'inline')) % custom kernel
    if isequal(ftype,'icdf')
        error(message('stats:ksdensity:IcdfNotAllowed'));
    else
        kernelcutoff = Inf;
    end
else
    error(message([errPrefix, 'UnknownKernelNameOrType']));
end
kernelInfo = struct();
kernelInfo.Fcn = kernel;
kernelInfo.IsCDF = iscdf; 
kernelInfo.Cutoff = kernelcutoff;
kernelInfo.Name = kernelname;
kernelInfo.FcnType = ftype;

% -----------------------------
% The following are functions that define smoothing kernels k(z).
% Each function takes a single input Z and returns the value of
% the smoothing kernel.  These sample kernels are designed to
% produce outputs that are somewhat comparable (differences due
% to shape rather than scale), so they are all probability
% density functions with unit variance.
%
% The density estimate has the form
%    f(x;k,h) = mean over i=1:n of k((x-y(i))/h) / h

function f = normal(z)
%NORMAL Normal density kernel.
f = exp(-0.5 * z .^2) ./ sqrt(2*pi);

function f = epanechnikov(z)
%EPANECHNIKOV Epanechnikov's asymptotically optimal kernel.
a = sqrt(5);
z = max(-a, min(z,a));
f = max(0,.75 * (1 - .2*z.^2) / a);

function f = box(z)
%BOX    Box-shaped kernel
a = sqrt(3);
f = (abs(z)<=a) ./ (2 * a);

function f = triangle(z)
%TRIANGLE Triangular kernel.
a = sqrt(6);
z = abs(z);
% In case z is Inf
f = zeros(size(z));
indomain = z<=a;
f(indomain) = (1 - z(indomain)/a) / a;

% -----------------------------
% The following are functions that define cdfs for smoothing kernels.

function f = cdf_nl(z)
%CDF_NL Normal kernel, cdf version
f = 0.5 * erfc(-z ./ sqrt(2));

function f = cdf_ep(z)
%CDF_EP Epanechnikov's asymptotically optimal kernel, cdf version
a = sqrt(5);
z = max(-a, min(z,a));
f = ((z+a) - (z.^3+a.^3)/15) * 3 / (4*a);

function f = cdf_bx(z)
%CDF_BX Box-shaped kernel, cdf version
a = sqrt(3);
f = max(0, min(1,(z+a)/(2*a)));

function f = cdf_tr(z)
%CDF_TR Triangular kernel, cdf version
a = sqrt(6);
denom = 12;  % 2*a^2
f = zeros(size(z));                     % -Inf < z < -a
t = (z>-a & z<0);
f(t) = (a + z(t)).^2 / denom;           % -a < z < 0
t = (z>=0 & z<a);
f(t) = .5 + z(t).*(2*a-z(t)) / denom;   % 0 < z < a
t = (z>a);
f(t) = 1;                               % a < z < Inf
