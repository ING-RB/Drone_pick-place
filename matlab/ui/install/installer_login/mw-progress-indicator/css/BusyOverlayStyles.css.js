define("mw-progress-indicator/css/BusyOverlayStyles.css", ["mw-widget-api/facade/forPrototyping/css"], function (css) {
  "use strict";

  var _exports = {};
  /* Copyright 2024 The MathWorks, Inc. */

  // contains all styles for Busy Overlay and its subcomponents
  const BusyOverlayStyles = css`
:host {
    display: none;
    outline: none;
    position: absolute;
    height: 100%;
    width: 100%;
    top: 0;
    left: 0;
}

:host([open]) {
    display: flex;
}

:host([open]:focus) {
    outline: 2px solid var(--mw-borderColor-focus);
}

:host::part(spinnerBgPanel) {
    position: absolute;
    top: 50%;
    left: 50%;
    border-radius: 4px;
    max-width: 50%;
    padding: 10px 20px;
    transform: translateX(-50%) translateY(-50%);
    z-index: 2000000000;
    outline: none;
    border: none;
    text-align: center;
}

:host::part(spinner) {
    outline: none;
    overflow: hidden;
}

:host::part(overlay) {
    border: none;
}

:host::part(spinnerContent) {
    font: 12px HelveticaNeue, Helvetica, Arial, Sans;
    color: var(--mw-color-primary);
    letter-spacing: 0.23px;
    text-align: center;
    margin-top: 10px;
    display: block;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

`;
  _exports.default = BusyOverlayStyles;
  return _exports.default;
});
//# sourceMappingURL=BusyOverlayStyles.css.js.map
