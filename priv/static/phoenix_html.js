"use strict";

(function() {
  function buildHiddenInput(name, value) {
    var input = document.createElement("input");
    input.type = "hidden";
    input.name = name;
    input.value = value;
    return input;
  }

  function handleClick(element) {
    var message = element.getAttribute("data-confirm");
    if(message && !window.confirm(message)) {
        return;
    }

    var to = element.getAttribute("data-to"),
        method = buildHiddenInput("_method", element.getAttribute("data-method")),
        csrf = buildHiddenInput("_csrf_token", element.getAttribute("data-csrf")),
        form = document.createElement("form"),
        target = element.getAttribute("target");

    form.method = (element.getAttribute("data-method") === "get") ? "get" : "post";
    form.action = to;
    form.style.display = "hidden";

    if (target) form.target = target;

    form.appendChild(csrf);
    form.appendChild(method);
    document.body.appendChild(form);
    form.submit();
  }

  window.addEventListener("click", function(e) {
    var element = e.target;

    while (element && element.getAttribute) {
      if(element.getAttribute("data-method")) {
        handleClick(element);
        e.preventDefault();
        return false;
      } else {
        element = element.parentNode;
      }
    }
  }, false);
})();
