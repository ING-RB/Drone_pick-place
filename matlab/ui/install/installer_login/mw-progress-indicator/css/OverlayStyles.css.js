define("mw-progress-indicator/css/OverlayStyles.css", ["mw-widget-api/facade/forPrototyping/css"], function (css) {
  "use strict";

  var _exports = {};
  /* Copyright 2024 The MathWorks, Inc. */

  // contains all styles for Overlay and its sub components
  const OverlayStyles = css`
:host {
    width: 100%;
    height: 100%;
    background-color: var(--mw-backgroundColor-tertiary);
    opacity: 0.85;
    z-index: 2000000000;
    outline: none;
    box-sizing: border-box;
}
`;
  _exports.default = OverlayStyles;
  return _exports.default;
});
//# sourceMappingURL=OverlayStyles.css.js.map
