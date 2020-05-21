$(function() {
  // $("form.delete").on('click', function() {
  //   // $("form.delete").toggle();
  //   var choice = confirm('you sure?');
  //   if (choice == true) {
  //     this.form.submit();
  //   } else {
  //     return false
  //   }
  // });

  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm('Are you sure? This cannot be undone!');
    if (ok) {
      // this.submit();

      // wraps form in jQuery, allowing methods to be called.
      var form = $(this);

      var request = $.ajax({
        // collect attributes from element
        url: form.attr("action"),
        method: form.attr("method")
      });

      // data is URL returned by sinatra code
      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status == 204) {
          form.parent("li").remove()
        } else if (jqXHR.status == 200) {
          document.location = data;
        }
      });

      // there should always be one of these
      request.fail();
    }
  });



});