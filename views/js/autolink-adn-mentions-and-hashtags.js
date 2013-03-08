/*
    A simple little script that finds all the App.net mentions and hashtags
    (as returned in the data.html property of the response envelope from the API)
    and makes them into links.

    Copyright © 2013, Aral Balkan. Released under the MIT license.
*/

window.addEventListener('load', function(){
	var nodes = document.querySelectorAll('[itemprop="mention"], [itemprop="hashtag"]');
	for (var i = 0; i < nodes.length; i++) {
		var node = nodes[i];

		var nodeType = node.getAttribute('itemprop')
		var link = document.createElement('a');
		var linkText = ''

		if (nodeType === 'mention')
		{
			// Configure @mention link.
    		var mentionName = node.getAttribute('data-mention-name');
    		link.setAttribute('href', 'http://alpha.app.net/' + mentionName);
    		link.setAttribute('alt', mentionName + ' on App.net.');
    		linkText = document.createTextNode('@' + mentionName);
		} else {
			// Configure hashtag link.
			var hashtagName = node.getAttribute('data-hashtag-name');
			link.setAttribute('href', 'http://alpha.app.net/hashtags/' + hashtagName);
			link.setAttribute('alt', 'View posts for the #' + hashtagName + ' on App.net' );
			linkText = document.createTextNode('#' + hashtagName);
		}

		link.appendChild(linkText);
		node.innerHTML = '';
		node.appendChild(link);
	}
});
