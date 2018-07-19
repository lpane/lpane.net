package App::Controller::Role::DateTime;

use Moo::Role;
use Method::Signatures;

method format_date($d) {
    # TODO
    # DateTime is too limited in formatting human readbale date.
    # Implement a datetime formatter module
    return "$d->day_name, $d->month_abbr $d->day"
}
1;
