$(document).ready(function() {

  $('#official-staff > #skunix').click(function() {
    $(this).addClass("active").siblings(".mh-member").removeClass("active");
    $('#mh-member-profile > #skunix').addClass("active").siblings(".mh-member-profile").removeClass("active");
  });

  // when user clicks a profile (#official-staff > #profile)
  // get specific name by id and store in variable

  // remove "active" class from all sibling elements
  // add "active" class to corresponding #mh-member-profile > #ID-matches-variable
});
