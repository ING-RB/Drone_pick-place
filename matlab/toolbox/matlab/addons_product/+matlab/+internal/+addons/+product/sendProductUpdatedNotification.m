function sendProductUpdatedNotification(baseCode)
% sendProductUpdatedNotification: Function notify Java Add-Ons desktop
% integration layer when a Product trial is installed

% Copyright 2023 The MathWorks Inc.
    
productManager = com.mathworks.addons_product.ProductManager;
productManager.refreshAndNotify(baseCode);
end