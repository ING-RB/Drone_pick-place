//  Copyright 2023 The MathWorks, Inc.

function setup (htmlComponent) {
    /* There are three states:
    1. pre-clicked
    2. clicked
    3. disabled */
    const button = document.getElementById('trainingStopButton');
    const spinner = document.getElementById('spinner');

    button.addEventListener('click', function (event) {
        if (!htmlComponent.Data.IsDisabled) {
            // Change the class of the button so that it switches to a clicked-state
            button.classList.add('clicked');
            spinner.classList.add('clicked');

            button.classList.remove('hover');

            htmlComponent.Data = { WasClicked: true, IsDisabled: false };
        }
    });

    button.addEventListener('mouseenter', function (event) {
        if (!htmlComponent.Data.WasClicked && !htmlComponent.Data.IsDisabled) {
            // Change the class of the button so that it switches to a clicked-state
            button.classList.add('hover');
        }
    });

    button.addEventListener('mouseleave', function (event) {
        if (!htmlComponent.Data.WasClicked && !htmlComponent.Data.IsDisabled) {
            // Change the class of the button so that it switches to a clicked-state
            button.classList.remove('hover');
        }
    });

    htmlComponent.addEventListener('DataChanged', function (event) {
        if (htmlComponent.Data.IsDisabled) {
            button.classList.remove('clicked');
            spinner.classList.remove('clicked');
            // Change the class of the button so that it switches to a disabled-state
            button.classList.add('disabled');
        }
    });
}
