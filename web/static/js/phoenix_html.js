// Although ^=parent is not technically correct,
// we need to use it in order to get IE8 support.
var elements = document.querySelectorAll('[data-submit^=parent]')
var len = elements.length

for (var i=0; i<len; ++i) {
  elements[i].addEventListener('click', function(event){
    var message = this.getAttribute("data-confirm")
    if(message === null || confirm(message)){
      this.parentNode.submit()
    };
    event.preventDefault()
    return false
  }, false)
}
