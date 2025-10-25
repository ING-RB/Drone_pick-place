function keywords(p)
%KEYWORDS Text strings that add symbols to titles and labels in POLARPATTERN.
%  Keywords are text strings that add extended ASCII symbols to dataset
%  labels and plot titles for use with POLARPATTERN.  Keywords may be added
%  anywhere in a string, and multiple keywords may be added.
%
%  Symbol keywords:
%     '#deg'    '#micro' '#infin'
%     '#plusmn' '#ohm'   '#nabla'
%     '#sup1'   '#sup2'  '#sup3'
%     '#dagger' '#copy'  '#reg'
%
%  Greek keywords:
%     '#alpha'      '#Alpha'
%     '#beta'       '#Beta'
%     '#gamma'      '#Gamma'
%     '#delta'      '#Delta'
%     '#epsilon'    '#Epsilon'
%     '#zeta'       '#Zeta'
%     '#eta'        '#Eta'
%     '#theta'      '#Theta'
%     '#kappa'      '#Kappa'
%     '#lambda'     '#Lambda'
%     '#mu'         '#Mu'
%     '#xi'         '#Xi'
%     '#pi'         '#Pi'
%     '#rho'        '#Rho'
%     '#sigma'      '#Sigma'
%     '#phi'        '#Phi'
%     '#psi'        '#Psi'
%     '#omega'      '#Omega'
%
%  See also polarpattern, createLabels, TitleTop, LegendLabels

if nargin > 0
    showBannerMessage(p,'Keywords shown in the command window.');
end
help internal.polari/keywords
