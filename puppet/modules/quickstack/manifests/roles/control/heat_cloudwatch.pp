#
class quickstack::roles::control::heat_cloudwatch (
) {
  class { '::heat::api_cloudwatch':
      enabled => 'true',
  }
}
