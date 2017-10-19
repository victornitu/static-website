window.updateTime = ->
  el = document.getElementById 'datetime'
  el.innerHTML = new Date().toLocaleTimeString()
  setTimeout updateTime, 1000