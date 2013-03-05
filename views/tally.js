var toggleState = false

window.onload = function () {

    var button = document.getElementById('highlight-template');

    button.onclick = function() {
        var nodes = document.querySelectorAll ('[data-qrepeat], [data-qtext], [data-qattr], [data-qif^="not:"], [data-qrepeat]');
        for (var i = 0; i < nodes.length; i++) {
            node = nodes[i];
            if (!toggleState) {
                node.classList.add('show');
            } else {
                node.classList.remove('show');
            }
        }
        toggleState = !toggleState;
        button.innerHTML = (toggleState ? 'Hide' : 'Show') + ' highlights';
    }

}
