require "curb"
require "json"

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
  msg = "#{Date.new(Time.now.year, Time.now.month, -1).month}月現在時点の時給#{time * ENV.fetch('HOURLY_WAGE').to_i}円"
  slack_post(msg)
end

def slack_post(msg)
  Curl.post(ENV.fetch("SLACK_WEBHOOKS_TOKEN"), { 
    channel: "#bot_tech",
    username: "時給",
    icon_emoji: ":moneybag:",
    text: msg
  }.to_json)
  puts msg
end
