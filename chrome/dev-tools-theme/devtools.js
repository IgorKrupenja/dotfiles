const request = new XMLHttpRequest();

request.open('GET', 'style.css');
request.onload = function () {
  chrome.devtools.panels.applyStyleSheet(request.responseText);
};
request.send();
