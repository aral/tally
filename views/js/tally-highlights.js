var toggleState = false;

window.addEventListener('load', function () {

    var button = document.getElementById('highlightTemplate');

    button.addEventListener ('click', function() {

        var nodes = document.querySelectorAll ('[data-tally-repeat], [data-tally-text], [data-tally-attr], [data-tally-if^="error"], [data-tally-if^="not:"], [data-tally-repeat], [data-tally-if="false"], [data-tally-dummy]');

        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i];
            if (!toggleState) {
                node.classList.add('show');
            } else {
                node.classList.remove('show');
            }
        }

        // Special case: although the Show highlights button is, itself, an element
        // ============= that will not show in the final template, let’s not dim it
        //               as it might look disabled to the user. Also it is clearly
        //               demarcated from the rest of the document as a control so it
        //               won’t be mistaken for a document item.
        //
        // NB. Also added the template summary to the special case.
        document.getElementById('tallyControls').classList.remove('show')
        document.getElementById('tally-template-summary').classList.remove('show')

        toggleState = !toggleState;
        button.innerHTML = (toggleState ? 'Hide' : 'Show') + ' highlights';
    });
});
