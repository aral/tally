// Generated by CoffeeScript 1.4.0
(function() {
  var app, data, express, superagent, tally, timer;

  express = require('express');

  tally = require('./lib/tally-express.coffee');

  superagent = require('superagent');

  timer = require('./lib/timer.coffee');

  timer.reset();

  app = express();

  app.engine('html', tally.__express);

  app.set('views', __dirname + '/views');

  app.use(express["static"]('views'));

  data = {
    title: 'Tally sample',
    name: 'Tally',
    content: 'This is a simple example to demonstrate Tally, a templating engine for Express 3 and client‐side JavaScript built on Distal, a JavaScript implementation of TAL from the Zope framework.',
    newURL: 'http://aralbalkan.com',
    correctURLFragment: 'moderniosdevelopment',
    aralImageURL: 'http://aralbalkan.com/images/aral.jpg',
    friends: [
      {
        name: 'Laura',
        skills: 'design, development, illustration, speaking'
      }, {
        name: 'Seb',
        skills: 'particles, games, JavaScript, C++'
      }, {
        name: 'Natalie',
        skills: 'HTML, CSS'
      }
    ]
  };

  app.get('/', function(request, response) {
    data.hybrid = false;
    return response.render('index.html', data);
  });

  app.get('/hybrid', function(request, response) {
    data.hybrid = true;
    return response.render('hybrid.html', data);
  });

  app.get('/posts', function(request, response) {
    timer.reset();
    return superagent.get('https://alpha-api.app.net/stream/0/posts/stream/global').end(function(globalTimelineResponse) {
      timer.elapsedTime('Data transfer from App.net');
      if (globalTimelineResponse.body) {
        globalTimelineResponse.body.numberOfPosts = function() {
          return this.data.length;
        };
        timer.reset();
        response.render('posts.html', globalTimelineResponse.body);
        return timer.elapsedTime('Template render');
      } else {
        return response.render('posts.html', {
          error: 'Bad response from Twitter'
        });
      }
    });
  });

  app.listen(3000);

  console.log('The Tally sample is listening on port 3000…');

  timer.elapsedTime('Server start');

}).call(this);
