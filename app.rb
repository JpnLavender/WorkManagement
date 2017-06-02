require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
# require "./work_management"

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Google Calendar API Ruby Quickstart'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "calendar-ruby-quickstart.yaml")
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY

def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(
    client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(
      base_url: OOB_URI)
    puts "Open the following URL in the browser and enter the " +
      "resulting code after authorization"
    puts url
    code = ENV["KEY"]
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI)
  end
  credentials
end

# Initialize the API
def main
  service = Google::Apis::CalendarV3::CalendarService.new
  service.client_options.application_name = APPLICATION_NAME
  service.authorization = authorize

  calendar_id = 'primary'
  response = service.list_events(calendar_id,
                                 time_min: Time.new(Time.now.year, Time.now.month).iso8601,
                                 time_max: Time.new(Time.now.year, Time.now.month, 31).iso8601
                                )

  puts "No upcoming events found" if response.items.empty?
  work_management_main(response)
end

def work_management_main(response)
  works = []
  response.items.each do |event|
    if event.summary =~ /#{ENV.fetch('WORK')}/
      start_time = event.start.date || event.start.date_time
      finish_time = event.end.date || event.end.date_time
      work_time =  (Time.parse(finish_time.to_s) - Time.parse(start_time.to_s) - 1800) / 3600
      works << work_time
    end
  end
  time = works.reduce(:+)
  puts "#{Date.new(Time.now.year, Time.now.month, -1).month}月現在時点の時給#{(time * ENV.fetch('HOURLY_WAGE').to_i).to_i}円"
end


main
