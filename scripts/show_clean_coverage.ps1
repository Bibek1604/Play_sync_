$output = dart run test_cov_console
$output | Where-Object { 
    return $_ -notmatch "no unit testing"
}
